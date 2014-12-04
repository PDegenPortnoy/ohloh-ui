#require File.dirname(__FILE__) + '/../test_helper'
require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  test 'should return fetch authorization that has not been invalidated and authorized' do 
    account = accounts(:jason)
    account.authorizations.create(:authorized_at => Time.now, :account_id => 1, :api_key_id => 1)
    account.authorizations.create(:account_id => 1, :api_key_id => 1)
    account.authorizations.create(:invalidated_at => Time.now - 1.day, :account_id => 1, :api_key_id => 1)

    assert_equal 1, account.authorizations.active.size
    assert_equal 'Test Application', account.authorizations.active.first.api_key.name
  end
end
