require 'test_helper'

class Account::FindTest < ActiveSupport::TestCase
  describe 'by_id_or_login' do
    let(:account) { create(:account) }

    it 'must find account by id' do
      found_account = Account::Find.by_id_or_login(account.id.to_s)
      found_account.must_equal account
    end

    it 'must find account by login' do
      found_account = Account::Find.by_id_or_login(account.login)
      found_account.must_equal account
    end

    it 'must find account case insensitive' do
      found_account = Account::Find.by_id_or_login(account.login.upcase)
      found_account.must_equal account
    end

    it 'must return nil for non existent value' do
      found_account = Account::Find.by_id_or_login('non_existent_login')
      found_account.must_be_nil
    end
  end
end
