require 'test_helper'
require 'oauth_test_helper'

class AuthorizationControllerTest < ActionController::TestCase
  fixtures :api_keys
  fixtures :accounts

  # Given a valid request, should create a new authorization and return its token and secret
  def test_request_token
    @options = default_oauth_parameters(api_keys(:first))
    @signature = OAuth::Signature::HMAC::SHA1.new(RequestMock.new('POST', @request.url + 'oauth/request_token', @options)) do
      [nil, api_keys(:first).secret]
    end
    assert_difference 'Authorization.count' do
      #binding.pry
      post :request_token, @options.merge(oauth_signature: @signature.signature)
    	assert_response :success
	  end
	  @authorization = api_keys(:first).reload.authorizations.first
	  assert @authorization
	  assert_equal "oauth_token=#{@authorization.token}&oauth_token_secret=#{@authorization.secret}", @response.body
  end

	# # An unsigned request_token gets a 401 Forbidden
	# def test_unsigned_request_token
	# 	@options = default_oauth_parameters(api_keys(:first))
	# 	assert_no_difference 'Authorization.count' do
	# 		post :request_token, @options
	# 		assert_response 401
	# 	end
	# end

	# def test_fails_unless_logged_in_for_revoke
 #    get :revoke, { :account_id => accounts(:joe).to_param, :id => 1 }
 #    assert_redirected_to new_session_path
 #  end

 #  def test_destroy
 #    authorization = mock('Authorization')
 #    api_key = mock("api_key", :name => 'Nice App')
 #    authorization.stubs(:id).returns('15')
 #    authorization.expects(:invalidate!)
 #    authorization.stubs(:api_key).returns(api_key)
 #    joe = accounts(:joe)
 #    login_as(:joe)
 #    authorizations = mock('authorizations')
 #    Account.any_instance.stubs(:authorizations).returns(authorizations)
 #    authorizations.expects(:find_by_id).with(authorization.id).returns(authorization)

 #    post :revoke, {:account_id => joe.to_param, :id => authorization.id}

 #    assert_equal 'You have successfully revoked the authorization for Nice App', flash[:success]
 #    assert_redirected_to edit_account_privacy_path(@joe)
 #  end

 #  def test_fails_for_revoke_for_non_admins_and_others
 #    login_as :robin
    
 #    get :revoke, { :account_id => accounts(:joe).to_param, :id => 1 }
 #    assert_redirected_to new_session_path
 #  end

	# # Given a request_token, present the user with authorization form
	# def test_authorize
	# 	login_as :joe
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	get :authorize, :oauth_token => @request_token.token
	# 	assert_response :success
	# 	assert_template 'authorizations/authorize'
	# end

	# def test_authorize_requires_login
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	get :authorize, :oauth_token => @request_token.token
	# 	assert_redirected_to new_session_path
	# end

	# # User grants the authorization request
	# def test_authorization_granted
	# 	login_as :joe
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	post :authorize, :oauth_token => @request_token.token, :authorize => '1'
	# 	assert_redirected_to account_authorizations_path(accounts(:joe))
	# 	@authorization = api_keys(:first).reload.authorizations.first
	# 	assert @authorization
	# 	assert @authorization.authorized?
	# end

	# # User denies the authorization request
	# def test_authorization_denied
	# 	login_as :joe
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	post :authorize, :oauth_token => @request_token.token, :authorize => '0'
	# 	assert_redirected_to account_authorizations_path(accounts(:joe))
	# 	@authorization = api_keys(:first).reload.authorizations.first
	# 	assert @authorization
	# 	assert @authorization.invalidated?
	# end

	# # We'll redirect wherever the consumer wants after a successful authorization
	# def test_authorization_redirect_option
	# 	login_as :joe
	# 	@callback_url = 'http://callback.com'
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	post :authorize, :oauth_token => @request_token.token, :authorize => '1', :oauth_callback => @callback_url
	# 	assert_redirected_to "#{@callback_url}?oauth_token=#{api_keys(:first).reload.authorizations.first.token}"
	# end

	# # get the access_token for an approved request_token
	# def test_access_token
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	@request_token.authorize!(accounts(:joe))
	# 	@options = default_oauth_parameters(api_keys(:first), @request_token)
	# 	@signature = OAuth::Signature::HMAC::SHA1.new(
	# 		RequestMock.new('POST', @request.url + 'oauth/access_token', @options)
	# 	) do
	# 		[@request_token.secret, api_keys(:first).secret]
	# 	end
	# 	assert_difference 'Authorization.count' do
	# 		post :access_token, @options.merge(:oauth_signature => @signature.signature)
	# 		assert_response :success
	# 	end
	# 	@authorization = AccessToken.find(:first)
	# 	assert @authorization
	# 	assert_equal "oauth_token=#{@authorization.token}&oauth_token_secret=#{@authorization.secret}", @response.body
	# end

	# # An unsigned access_token gets a 401 Forbidden
	# def test_unsigned_access_token
	# 	@request_token = RequestToken.create :api_key => api_keys(:first)
	# 	@request_token.authorize!(accounts(:joe))
	# 	@options = default_oauth_parameters(api_keys(:first), @request_token)
	# 	assert_no_difference 'Authorization.count' do
	# 		post :access_token, @options
	# 		assert_response 401
	# 	end
	# end
end
