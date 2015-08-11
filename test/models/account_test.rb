require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  let(:account) { create(:account) }
  let(:admin) { create(:admin) }

  it '#sent_kudos' do
    Kudo.delete_all
    create(:kudo, sender: admin, account: accounts(:user))
    create(:kudo, sender: admin, account: accounts(:joe))

    admin.sent_kudos.count.must_equal 2
  end

  it '#claimed_positions' do
    proj = create(:project)
    create_position(account: account, project: proj)
    account.positions.count.must_equal 1
    account.claimed_positions.count.must_equal 1
  end

  it 'the account model should be valid' do
    account = build(:account)
    account.must_be :valid?
  end

  it 'it should validate email and email_confirmation' do
    account = build(:account)
    account.email = 'ab'
    account.wont_be :valid?
    account.errors.must_include(:email)
    account.errors.must_include(:email_confirmation)
    expected_error_message = ['is too short (minimum is 3 characters)', I18n.t('accounts.invalid_email_address')]
    account.errors.messages[:email].must_equal expected_error_message
    account.errors.messages[:email_confirmation].must_equal ['doesn\'t match Email']
  end

  it 'it should validate URL format when value is available' do
    account = build(:account)
    account.must_be :valid?

    account = build(:account, url: '')
    account.must_be :valid?

    account = build(:account, url: 'openhub.net')
    account.wont_be :valid?
    account.errors.must_include(:url)
    account.errors.messages[:url].first.must_equal I18n.t('accounts.invalid_url_format')
  end

  it 'it should validate login' do
    account = build(:account)
    account.must_be :valid?

    account = build(:account, login: '')
    account.wont_be :valid?
    expected_error_message =
      ['can\'t be blank', 'is too short (minimum is 3 characters)',
       I18n.t('activerecord.errors.models.account.attributes.login.invalid')]
    account.errors.messages[:login].must_equal expected_error_message

    create(:account, login: 'openhub_dev')
    account = build(:account, login: 'openhub_dev')
    account.wont_be :valid?
    account.errors.must_include(:login)
    account.errors.messages[:login].must_equal ['has already been taken']
  end

  it 'it should validate password' do
    account = build(:account)
    account.must_be :valid?

    account = build(:account, password: '')
    account.wont_be :valid?
    account.errors.must_include(:password)
    account.errors.messages[:password].first.must_equal 'Please provide a password.'

    account = build(:account, password: 'abc12345', password_confirmation: 'ABC12345')
    account.wont_be :valid?
    account.errors.must_include(:password_confirmation)
    error_message = account.errors.messages[:password_confirmation]
    error_message.must_equal ['Please enter the same password in the confirmation field.']
  end

  it 'it should validate twitter account only if its present' do
    account = build(:account)
    account.must_be :valid?

    account = build(:account, twitter_account: '')
    account.must_be :valid?

    account = build(:account, twitter_account: 'abcdefghijklmnopqrstuvwxyz')
    account.wont_be :valid?
    account.errors.must_include(:twitter_account)
    account.errors.messages[:twitter_account].must_equal ['is too long (maximum is 15 characters)']
  end

  it 'it should validate user full name' do
    account = build(:account)
    account.must_be :valid?

    account = build(:account, name: '')
    account.must_be :valid?

    account = build(:account, name: Faker::Name.name * 8)
    account.wont_be :valid?
    account.errors.must_include(:name)
    account.errors.messages[:name].must_equal ['is too long (maximum is 50 characters)']
  end

  it 'it should update the markup(about me) when updating a record' do
    account = create(:account)
    about_me = Faker::Lorem.paragraph(2)
    account.about_raw = about_me
    account.save
    account.markup.raw.must_equal about_me
  end

  it 'it should not update the markup(about me) when exceeding the limit' do
    about_me = Faker::Lorem.paragraph(130)
    account.about_raw = about_me
    account.wont_be :valid?
    account.markup.errors.must_include(:raw)
  end

  it 'it should error out when affiliation_type is not specified' do
    account.affiliation_type = ''
    account.wont_be :valid?
    account.errors.must_include(:affiliation_type)
    account.errors.messages[:affiliation_type].first.must_equal I18n.t(:is_invalid)
  end

  it 'should search by login and sort by position and char length' do
    create(:account, login: 'test')
    create(:account, login: 'account_test', email: 'test2@openhub.net', email_confirmation: 'test2@openhub.net')
    create(:account, login: 'tester', email: 'test3@openhub.net', email_confirmation: 'test3@openhub.net')
    create(:account, login: 'unittest', email: 'test4@openhub.net', email_confirmation: 'test4@openhub.net')
    create(:account, login: 'unittest1', email: 'test5@openhub.net', email_confirmation: 'test5@openhub.net')
    account_search = Account.simple_search('test')
    account_search.size.must_equal 5
    account_search.first.login.must_equal 'test'
    account_search.second.login.must_equal 'tester'
    account_search.third.login.must_equal 'unittest'
    account_search.fourth.login.must_equal 'unittest1'
    account_search.fifth.login.must_equal 'account_test'
  end

  it 'should return recently active accounts' do
    name_facts(:vitafact).update_attributes(last_checkin: Time.current)
    recently_active = Account.recently_active
    recently_active.wont_be_nil
    recently_active.count.must_equal 1
  end

  it 'should not return non recently active accounts' do
    recently_active = Account.recently_active
    recently_active.must_be_empty
    recently_active.count.must_equal 0
  end

  it 'it should error out when affiliation_type is specified and org name is blank' do
    account.affiliation_type = 'specified'
    account.organization_id = ''
    account.wont_be :valid?
    account.errors.must_include(:organization_id)
    account.errors.messages[:organization_id].first.must_equal I18n.t(:cant_be_blank)
  end

  it 'facts_joins should accounts with positions projects and name_facts' do
    analysis = analyses(:linux)
    project = projects(:linux)
    project.editor_account = account
    project.update_attributes! best_analysis_id: analysis.id

    accounts_with_facts = Account.with_facts
    accounts_with_facts.size.must_equal 2
    accounts_with_facts.first.name.must_equal 'admin Allen'
    accounts_with_facts.last.name.must_equal 'user Luckey'
  end

  it 'should validate current password error message' do
    account.update(password: 'newpassword', password_confirmation: 'newpassword', current_password: 'dummy password')
    account.errors.size.must_equal 1
    error_message = [I18n.t('activerecord.errors.models.account.attributes.current_password.invalid')]
    error_message.must_equal account.errors[:current_password]
  end

  it 'should update password and password_confirmation with valid passwords' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: 'newpassword', password_confirmation: 'newpassword', current_password: 'testing')
    account.reload.crypted_password.must_equal Account::Authenticator.encrypt('newpassword', account.salt)
  end

  it 'should not update password and password_confirmation if current_password is an empty string' do
    account.update(password: 'newpassword', password_confirmation: 'newpassword', current_password: '')
    assert_not_equal account.reload.crypted_password, Account::Authenticator.encrypt('newpassword', account.salt)
  end

  it 'should not update if password and password_confirmation do not match' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: 'foobar', password_confirmation: 'barfoo', current_password: 'testing')
    assert account.invalid?
  end

  it 'should not update if password and password_confirmation are blank' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: '', password_confirmation: '', current_password: 'testing')
    assert account.invalid?
  end

  it 'should not update if password is blank' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: '', password_confirmation: 'foobar', current_password: 'testing')
    assert account.invalid?
  end

  it 'should not update if password_confirmation is blank' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: 'foobar', password_confirmation: '', current_password: 'testing')
    assert account.invalid?
  end

  it 'should not update password if password is less than 5 characters' do
    account = create(:account, password: 'testing', password_confirmation: 'testing')
    account.update(password: 'pass', password_confirmation: 'pass', current_password: 'testing')
    assert account.invalid?
  end

  it 'it should get the first commit date for a account position' do
    user = accounts(:user)
    expected_date = Time.strptime('2008-02-09', '%Y-%m-%d').to_date.beginning_of_month
    user.first_commit_date.must_equal expected_date
  end

  it 'it should return nil when account has no best_vita' do
    admin.first_commit_date.must_be_nil
  end

  describe 'login validations' do
    it 'test should require login' do
      assert_no_difference 'Account.count' do
        account = build(:account, login: nil)
        account.valid?
        account.errors.messages[:login].must_be :present?
      end
    end

    it 'test valid logins' do
      account = build(:account)
      logins = %w(rockola ROCKOLA Rockola Rock_Ola F323)

      logins.each do |login|
        account.login = login
        account.must_be :valid?
      end
    end

    it 'test login not urlable' do
      account = build(:account)
      bad_logins = %w(123 user.allen $foo])

      bad_logins.each do |bad_login|
        account.login = bad_login
        account.wont_be :valid?
      end
    end

    it 'test bad login on create' do
      account = build(:account, login: '$foo')
      account.valid?
      account.errors.messages[:login].must_be :present?
    end

    it 'test login on update' do
      # fake a bad login already in the db
      account = create(:account)
      account.login = '$bad_login$'
      account.save(validate: false).wont_equal false

      # ok, now update something else than login
      account.reload
      account.name = 'My New Name'
      account.save.wont_equal false

      # ok, now try updating the name to something new, yet still wrong
      account.reload
      account.login = '$another_bad_login$'
      account.save.must_equal false
      account.errors.messages[:login].must_be :present?
    end
  end

  describe 'most_experienced_language' do
    it 'must return the language having a vita_language_fact' do
      create(:language, category: 0)
      lang_2 = create(:language, category: 2)
      vita = create(:vita)
      vita.account.update!(best_vita_id: vita.id)
      create(:vita_language_fact, language: lang_2, vita: vita)

      lang_2.nice_name.must_equal vita.account.most_experienced_language.nice_name
    end

    it 'must return the language with lowest category' do
      lang_1 = create(:language, category: 0)
      lang_2 = create(:language, category: 2)
      vita = create(:vita)
      vita.account.update!(best_vita_id: vita.id)
      create(:vita_language_fact, language: lang_1, total_commits: 0, vita: vita)
      create(:vita_language_fact, language: lang_2, total_commits: 300, vita: vita,
                                  total_activity_lines: 200, total_months: 30)

      lang_1.nice_name.must_equal vita.account.most_experienced_language.nice_name
    end
  end

  describe 'to_param' do
    it 'must return login when it is urlable' do
      account = build(:account, login: 'stan')
      account.to_param.must_equal account.login
    end

    it 'must return id when login is not urlable' do
      account = accounts(:user)
      account.login = '$one'
      account.to_param.must_equal account.id.to_s
    end
  end

  it '#email_topics' do
    admin.email_topics?.must_equal true
    admin.email_master = true
    admin.email_posts = false
    admin.email_topics?.must_equal false
    admin.email_master = true
    admin.email_posts = true
    admin.email_topics?.must_equal true
    admin.email_master = false
    admin.email_posts = true
    admin.email_topics?.must_equal false
  end

  it '#email_kudos' do
    admin.email_kudos?.must_equal true
    admin.email_master = true
    admin.email_kudos = false
    admin.email_kudos?.must_equal false
    admin.email_master = true
    admin.email_kudos = true
    admin.email_kudos?.must_equal true
    admin.email_master = false
    admin.email_kudos = true
    admin.email_kudos?.must_equal false
  end

  it '#update_akas' do
    projects(:ohloh).update!(best_analysis_id: create(:analysis).id, editor_account: accounts(:user))
    position = create_position(project: projects(:ohloh), account: accounts(:user))
    accounts(:user).update_akas
    accounts(:user).akas.split("\n").sort.must_equal [position.name.name, 'User'].sort
  end

  it '#links' do
    linux = projects(:linux)
    linux.editor_account = account
    link = linux.links.new(
      url: 'http://www.google.com',
      title: 'title',
      link_category_id: Link::CATEGORIES[:Other]
    )
    link.editor_account = account
    link.save!
    account.links.must_include(link)
  end

  it 'badges list' do
    account = accounts(:user)
    badges = %w(badge1 badge2)
    Badge.expects(:all_eligible).with(account).returns(badges)
    account.badges.must_equal badges
  end

  it '#non_human_ids' do
    ohloh_slave_id = Account.hamster.id
    uber_data_crawler_id = Account.uber_data_crawler.id

    Account.non_human_ids.size.must_equal 2
    Account.non_human_ids.must_include(ohloh_slave_id)
    Account.non_human_ids.must_include(uber_data_crawler_id)
  end

  describe 'validations' do
    it 'should require password' do
      assert_no_difference 'Account.count' do
        user = build(:account, password: nil)
        user.valid?
        user.errors.messages[:password].must_be :present?
      end
    end

    it 'should require password confirmation' do
      assert_no_difference 'Account.count' do
        user = build(:account, password_confirmation: nil)
        user.valid?
        user.errors.messages[:password_confirmation].must_be :present?
      end
    end

    it 'it should require email confirmation' do
      assert_no_difference 'Account.count' do
        user = build(:account, email_confirmation: '')
        user.valid?
        user.errors.messages[:email_confirmation].must_be :present?
        user.errors.messages[:email_confirmation].first.must_equal %(doesn't match Email)
      end
    end

    it 'email & email confirmation shouldn\'t be blank' do
      assert_no_difference 'Account.count' do
        user = build(:account, email_confirmation: '', email: '')
        user.valid?
        user.errors.messages[:email_confirmation].must_be :present?

        user.errors.messages[:email_confirmation].first.must_equal I18n.t('accounts.invalid_email_address')
      end
    end

    it 'email & email confirmation is blank and should raise error' do
      assert_no_difference 'Account.count' do
        user = build(:account, email_confirmation: '', email: 'rapbhan@rapbhan.com')
        user.valid?
        user.errors.messages[:email_confirmation].must_be :present?
        user.errors.messages[:email_confirmation].first.must_equal %(doesn't match Email)
      end
    end

    it 'must validate format of organization_name' do
      account = build(:account)
      account.affiliation_type = 'other'
      account.organization_name = '_org'
      account.valid?

      message = I18n.t('activerecord.errors.models.account.attributes.organization_name.invalid')
      account.errors.messages[:organization_name].first.must_equal message
    end

    it 'must validated length of organization_name' do
      account = build(:account)
      account.affiliation_type = 'other'
      account.organization_name = 'A1'
      account.valid?

      message = 'is too short (minimum is 3 characters)'
      account.errors.messages[:organization_name].first.must_equal message
    end

    it 'must allow blank organization_name' do
      account = build(:account)
      account.affiliation_type = 'specified'
      account.organization_name = ''
      account.valid?

      account.errors.messages[:organization_name].must_be_nil
    end

    describe 'twitter_id' do
      it 'wont validate uniqueness when value is nil' do
        create(:account, twitter_id: nil)

        build(:account, twitter_id: nil).must_be :valid?
      end

      it 'must validate uniqueness when value is non null' do
        account = create(:account)

        new_account = build(:account, twitter_id: account.twitter_id)

        new_account.wont_be :valid?
        new_account.errors.messages[:twitter_id].must_be :present?
      end
    end
  end

  it 'disallow html tags in url' do
    account = create(:account, url: 'http://www.ohloh.net/')
    account.must_be :valid?

    account.url = %q(http://1.cc/ <img src="s" onerror="top.location=' http://vip-feed.com/35898/buy+adderall.html';">)
    account.wont_be :valid?
    account.errors.messages[:url].must_be :present?
  end

  it 'must create an organization job when account is deleted' do
    account = create(:account)
    organization = create(:organization)
    account.update_attribute(:organization_id, organization.id)

    Job.delete_all
    account.destroy

    OrganizationJob.count.must_equal 1
    OrganizationJob.first.organization_id.must_equal organization.id
  end

  it 'must create 2 organization jobs for a change in organization_id' do
    organization = create(:organization)
    account = create(:account, organization_id: organization.id)

    Job.delete_all
    account.update!(organization_id: create(:organization).id)

    OrganizationJob.count.must_equal 2
  end

  describe 'kudo_rank' do
    it 'should return 1 if kudo_rank is nil' do
      admin.person.update_column(:kudo_rank, nil)
      admin.kudo_rank.must_equal 1
    end

    it 'should return kudo_rank' do
      accounts(:user).kudo_rank.must_equal 10
    end
  end

  describe 'best_vita' do
    it 'should return nil_vita when best_vita is absent' do
      admin.best_vita.class.must_equal NilVita
    end

    it 'should return best_vita when available' do
      vita = create(:best_vita, account_id: account.id)
      account.update_column(:best_vita_id, vita.id)
      account.best_vita.class.must_equal Vita
    end
  end

  describe 'most_experienced_language' do
    it 'should return nil when vita_language_facts is empty' do
      admin.most_experienced_language.must_equal nil
    end

    it 'should return language name when vita_language_facts is present' do
      vita = create(:best_vita, account_id: account.id)
      account.update_column(:best_vita_id, vita.id)
      language_fact = create(:vita_language_fact, vita_id: vita.id)

      account.most_experienced_language.nice_name.must_equal language_fact.language.nice_name
    end
  end

  describe 'anonymous?' do
    it 'should return true for anonymous account' do
      account = AnonymousAccount.create!
      account.anonymous?.must_equal true
    end

    it 'should return false for normal account' do
      admin.anonymous?.must_equal false
    end
  end

  describe 'edit_count' do
    it 'should return the no of undone edits' do
      CreateEdit.create(target: admin, account_id: admin.id)
      CreateEdit.create(target: admin, account_id: admin.id, undone: true)
      admin.edit_count.must_equal 1
    end
  end

  describe 'badges' do
    it 'should return all eligible badges' do
      fosser_badge = FOSSerBadge.new(admin)
      Badge.stubs(:all_eligible).returns([fosser_badge])
      admin.badges.must_equal [fosser_badge]
    end
  end

  describe 'find_or_create_anonymous_account' do
    it 'should create anonymous account if it does not exist' do
      Account.find_or_create_anonymous_account.login.must_equal AnonymousAccount::LOGIN
    end

    it 'should find anonymous account if it exists' do
      anonymous_account = AnonymousAccount.create!
      Account.find_or_create_anonymous_account.must_equal anonymous_account
    end
  end

  describe 'resolve_login' do
    it 'should find account by login' do
      admin.update_column(:login, 'test')
      Account.resolve_login('Test').must_equal admin
      Account.resolve_login('tEst').must_equal admin
      Account.resolve_login('test').must_equal admin
    end
  end

  describe 'ip' do
    it 'should return ip if defined' do
      admin.ip = '127.0.0.1'
      admin.ip.must_equal '127.0.0.1'
    end

    it 'should return ip as 0.0.0.0 if not defined' do
      admin.ip.must_equal '0.0.0.0'
    end
  end

  describe 'links' do
    it 'should return links' do
      project = create(:project)
      link = create(:link, project: project)
      CreateEdit.create!(target_id: link.id, project_id: project.id, target_type: 'Link', account_id: admin.id)

      admin.links.must_equal [link]
    end
  end

  describe 'resend_activation!' do
    it 'should resent activation email and update sent at timestamp' do
      ActionMailer::Base.deliveries.clear

      admin.resend_activation!
      email = ActionMailer::Base.deliveries.last
      email.to.must_equal [admin.email]
      email.subject.must_equal I18n.t('account_mailer.signup_notification.subject')
    end
  end

  describe 'run_actions' do
    it 'should run all actions for the account' do
      account = create(:account)
      project = create(:project)
      action = Action.create(account: account, stack_project: project, status: 'completed')

      account.reload
      account.run_actions('completed')
      action.reload
      action.status.must_equal Action::STATUSES[:remind]
    end
  end

  describe 'from_param' do
    it 'should match account login' do
      account = create(:account)
      Account.from_param(account.login).first.id.must_equal account.id
    end

    it 'should match account id as string' do
      account = create(:account)
      Account.from_param(account.id.to_s).first.id.must_equal account.id
    end

    it 'should match account id as integer' do
      account = create(:account)
      Account.from_param(account.id).first.id.must_equal account.id
    end

    it 'should not match spammers' do
      account = create(:account)
      Account.from_param(account.to_param).count.must_equal 1
      Account::Access.new(account).spam!
      Account.from_param(account.to_param).count.must_equal 0
    end
  end

  describe 'active' do
    it 'should return active accounts' do
      account1 = create(:account, level: -20)
      account2 = create(:account, level: 0)
      account3 = create(:account, level: 10)

      Account.active.wont_include account1
      Account.active.must_include account2
      Account.active.wont_include account3
    end
  end
end
