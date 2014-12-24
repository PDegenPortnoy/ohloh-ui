require 'test_helper'

class ManageTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  fixtures :accounts, :projects, :organizations

  def test_create_requires_project
    manage = Manage.create(account: accounts(:admin))
    assert manage.errors.include?(:target)
  end

  def test_create_requires_account
    manage = Manage.create(target: projects(:linux))
    assert manage.errors.include?(:account)
  end

  def test_create_should_work
    manage = Manage.create(target: projects(:linux), account: accounts(:admin))
    manage.update_attributes!(approver: accounts(:user))
    assert manage.errors.empty?
    assert projects(:linux).managers.include?(accounts(:admin))
    assert accounts(:admin).projects.include?(projects(:linux))
  end

  def test_create_should_fail_on_maximum
    Manage.any_instance.expects(:over_management_limit?).returns(true)
    manage = Manage.create(account: accounts(:joe), target: projects(:linux))
    assert manage.errors.include?(:maximum)
  end

  def test_create_fail_on_uniqueness
    Manage.create!(account: accounts(:admin), target: projects(:linux))
    manage = Manage.create(account: accounts(:admin), target: projects(:linux))
    assert manage.errors.include?(:target_id)
  end

  def test_add_approver
    Manage.create!(account: accounts(:joe), target: projects(:linux))
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    assert_nil manage.approver
    manage.update_attributes!(approver: accounts(:user))
    manage.reload
    assert_equal accounts(:user), manage.approver
  end

  def test_active_manager_succeeds
    projects(:linux).manages.destroy_all
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    manage.update_attributes!(approver: accounts(:user))
    assert projects(:linux).reload.active_managers.include?(accounts(:admin))
  end

  def test_active_manager_fails_if_deleted
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux), deleted_at: Time.now.utc)
    manage.update_attributes!(approver: accounts(:user))
    assert !projects(:linux).reload.active_managers.include?(accounts(:admin))
  end

  def test_active_manager_includes_auto_approved
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    assert_not_nil manage
    assert projects(:linux).reload.active_managers.include?(accounts(:admin))
  end

  def test_destroy_by_succeeds
    # make user an admin
    manage = Manage.create!(account: accounts(:user), target: projects(:linux))
    manage.update_attributes!(approver: accounts(:admin))
    assert projects(:linux).reload.active_managers.include?(accounts(:user))

    # create a manage entry for admin
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    assert_equal nil, manage.destroyer

    # user destroys it
    assert projects(:linux).reload.managers.include?(accounts(:admin))
    manage.destroy_by!(accounts(:user))
    assert !projects(:linux).reload.managers.include?(accounts(:admin))
    assert_equal accounts(:user), manage.reload.destroyer
  end

  def test_destroy_by_fails_if_destroyer_isnt_admin
    # create a manage entry for admin
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    manage.update_attributes!(approver: accounts(:user))
    assert_equal nil, manage.destroyer

    # user destroys it
    assert_raise(RuntimeError) { manage.destroy_by!(accounts(:user)) }
  end

  def test_destroy_by_fails_if_destroyer_isnt_approved
    Manage.create!(account: accounts(:joe), target: projects(:linux)) # auto-approved
    manage = Manage.create!(account: accounts(:user), target: projects(:linux))
    assert !projects(:linux).reload.active_managers.include?(accounts(:user))

    # create a manage entry for admin
    manage = Manage.create!(account: accounts(:admin), target: projects(:linux))
    assert_equal nil, manage.destroyer

    # user destroys it
    assert_raise(RuntimeError) { manage.destroy_by!(accounts(:user)) }
  end

  def test_destroy_by_fails_if_destroyer_deleted
    # make user an admin
    manage1 = Manage.create!(account: accounts(:user), target: projects(:linux), deleted_at: Time.now.utc)
    manage1.update_attributes!(approver: accounts(:user))

    # create a manage entry for admin
    manage2 = Manage.create!(account: accounts(:admin), target: projects(:linux))
    assert_equal nil, manage2.destroyer

    # user destroys it
    assert_raise(RuntimeError) { manage2.destroy_by!(accounts(:user)) }
  end

  def test_pending_fails_if_approved
    manage = Manage.create!(account: accounts(:user), target: projects(:linux))
    manage.update_attributes!(approver: accounts(:user))
    assert_equal false, manage.pending?
  end

  def test_pending_fails_if_destroyed
    manage = Manage.create!(account: accounts(:user), target: projects(:linux), destroyer: accounts(:user))
    assert_equal false, manage.pending?
  end

  def test_pending_fails_if_destroyed_and_approved
    manage = Manage.create!(account: accounts(:user), target: projects(:linux), destroyer: accounts(:user))
    manage.update_attributes!(approver: accounts(:user))
    assert_equal false, manage.pending?
  end

  def test_approve!
    m1 = Manage.create!(target: projects(:linux), account: accounts(:admin))
    assert_equal Account.hamster, m1.approver
    m2 = Manage.create!(target: projects(:linux), account: accounts(:user))
    assert_equal nil, m2.approver
    m2.approve!(accounts(:admin))
    assert projects(:linux).active_managers.include?(accounts(:user))
  end

  def test_should_list_all_the_active_managers_for_an_organization
    organizations(:linux).manages.destroy_all
    manage = Manage.create!(account: accounts(:admin), target: organizations(:linux))
    Manage.create!(account: accounts(:user), target: projects(:linux), approver: accounts(:admin))
    Manage.create!(account: accounts(:joe), target: projects(:adium), approver: accounts(:admin))
    manage.update_attributes!(approver: accounts(:user))
    assert_equal accounts(:admin).reload.manages.organizations.first.target, organizations(:linux)
    assert_equal 3, Manage.count
    assert_equal 1, Manage.organizations.count
  end

  def test_rejection_mail_sent
    Manage.create!(account: accounts(:admin), target: projects(:linux))
    application = Manage.create!(account: accounts(:user), target: projects(:linux))

    # sends one mail to admins (admin) and a different one to applicant (user)
    assert_emails 2 do
      application.update_attributes!(destroyer: accounts(:admin))
    end
  end

  def test_approve_mail_sent
    Manage.create!(account: accounts(:admin), target: projects(:linux))
    application = Manage.create!(account: accounts(:user), target: projects(:linux))

    # sends one mail to admins (admin) and a different one to applicant (user)
    assert_emails 1 do
      application.update_attributes!(approver: accounts(:admin))
    end
  end

  def test_application_mail_sent_1
    Manage.create!(account: accounts(:admin), target: projects(:linux))

    # sends one mail to admin
    assert_emails 1 do
      Manage.create!(account: accounts(:user), target: projects(:linux))
    end
  end

  def test_application_mail_sent_2
    Manage.create!(account: accounts(:admin), target: projects(:linux))
    application = Manage.create!(account: accounts(:user), target: projects(:linux))

    # sends one mail to admin
    assert_emails 1 do
      application.update_attributes!(destroyer: accounts(:user))
    end
  end

  def test_remove_existing_manager
    Manage.create!(account: accounts(:admin), target: projects(:linux))
    application = Manage.create!(account: accounts(:user), target: projects(:linux), approver: accounts(:admin))
    assert_equal 2, projects(:linux).active_managers.count

    # sends one mail to admins (admin) and a different one to applicant (user)
    assert_emails 2 do
      application.update_attributes!(destroyer: accounts(:user))
    end
  end
end
