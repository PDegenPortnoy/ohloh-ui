require 'test_helper'

class ApiKeysControllerTest < ActionController::TestCase
  before do
    @admin = create(:admin, name: 'xyzzy-admin')
    @user = create(:account, name: 'user_api_keys_test')
  end

  # index action
  it 'admins should be able to look at the global list of api keys' do
    login_as @admin
    get :index
    must_respond_with :ok
  end

  it 'unlogged in users should not be able to look at the global list of api keys' do
    login_as nil
    get :index
    must_respond_with :redirect
    must_redirect_to new_session_path
  end

  it 'normal users should not be able to look at the global list of api keys' do
    login_as @user
    get :index
    must_respond_with :unauthorized
  end

  it 'index page should find models whose oauth_application.name match the "q" parameter' do
    api_key1 = create(:api_key)
    api_key2 = create(:api_key)
    api_key1.oauth_application.update! name: 'foobar'
    login_as @admin
    get :index, query: 'foobar'
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'index page should find models whose description match the "q" parameter' do
    api_key1 = create(:api_key, description: 'foobar')
    api_key2 = create(:api_key, description: 'goobaz')
    login_as @admin
    get :index, query: 'foobar'
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'index page should find models whose oauth_application.uid match the "q" parameter' do
    api_key1 = create(:api_key)
    api_key2 = create(:api_key)
    login_as @admin
    get :index, query: api_key1.oauth_application.uid
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'index page should find models whose account name match the "q" parameter' do
    api_key1 = create(:api_key, account_id: @user.id)
    api_key2 = create(:api_key, account_id: @admin.id)
    login_as @admin
    get :index, query: @user.name
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'index page should accept "query" in place of "q" as a parameter' do
    api_key1 = create(:api_key)
    api_key2 = create(:api_key)
    login_as @admin
    get :index, query: api_key1.oauth_application.name
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'index page should honor the sort order "most_recent_request"' do
    api_key1 = create(:api_key, last_access_at: Time.current)
    api_key2 = create(:api_key, last_access_at: Time.current - 1.day)
    api_key3 = create(:api_key, last_access_at: Time.current + 1.day)
    login_as @admin
    get :index, sort: 'most_recent_request'
    must_respond_with :ok
    pattern = [api_key3, api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should honor the sort order "most_requests_today"' do
    api_key1 = create(:api_key, daily_count: 11)
    api_key2 = create(:api_key, daily_count: 10)
    api_key3 = create(:api_key, daily_count: 12)
    login_as @admin
    get :index, sort: 'most_requests_today'
    must_respond_with :ok
    pattern = [api_key3, api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should honor the sort order "most_requests"' do
    api_key1 = create(:api_key, total_count: 11)
    api_key2 = create(:api_key, total_count: 10)
    api_key3 = create(:api_key, total_count: 12)
    login_as @admin
    get :index, sort: 'most_requests'
    must_respond_with :ok
    pattern = [api_key3, api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should honor the sort order "newest"' do
    api_key1 = create(:api_key, created_at: Time.current)
    api_key2 = create(:api_key, created_at: Time.current - 1.day)
    api_key3 = create(:api_key, created_at: Time.current + 1.day)
    login_as @admin
    get :index, sort: 'newest'
    must_respond_with :ok
    pattern = [api_key3, api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should honor the sort order "oldest"' do
    api_key1 = create(:api_key, created_at: Time.current)
    api_key2 = create(:api_key, created_at: Time.current - 1.day)
    api_key3 = create(:api_key, created_at: Time.current + 1.day)
    login_as @admin
    get :index, sort: 'oldest'
    must_respond_with :ok
    pattern = [api_key2, api_key1, api_key3].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should honor the sort order "account_name"' do
    api_key1 = create(:api_key, account_id: @user.id, created_at: Time.current - 1. day, name: 'Zzzzzzzz')
    api_key2 = create(:api_key, account_id: @admin.id, created_at: Time.current, name: 'Aaaaaaaa')
    login_as @admin
    get :index, sort: 'account_name'
    must_respond_with :ok
    pattern = [api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'index page should assume "newest" when the sort parameter is unsupported' do
    api_key1 = create(:api_key, created_at: Time.current)
    api_key2 = create(:api_key, created_at: Time.current - 1.day)
    api_key3 = create(:api_key, created_at: Time.current + 1.day)
    login_as @admin
    get :index, sort: 'I_am_a_banana!'
    must_respond_with :ok
    pattern = [api_key3, api_key1, api_key2].map { |api_key| api_key.oauth_application.name }
              .join('.*')
    response.body.must_match(/#{ pattern }/m)
  end

  it 'admins should be able to look at the api keys of someone else' do
    login_as @admin
    get :index, account_id: @user.id
    must_respond_with :ok
  end

  it 'unlogged in users should not be able to look at the api keys of a user' do
    login_as nil
    get :index, account_id: @user.id
    must_respond_with :redirect
    must_redirect_to new_session_path
  end

  it 'normal users should be able to look at their own api keys' do
    login_as @user
    get :index, account_id: @user.id
    must_respond_with :ok
  end

  it 'normal users should not be able to look at someone elses api keys' do
    login_as @user
    get :index, account_id: @admin.id
    must_respond_with :unauthorized
  end

  it 'normal users should see their api keys, but not others' do
    api_key1 = create(:api_key, account_id: @user.id)
    api_key2 = create(:api_key, account_id: @admin.id)
    login_as @user
    get :index, account_id: @user.id
    must_respond_with :ok
    response.body.must_match(api_key1.oauth_application.name)
    response.body.wont_match(api_key2.oauth_application.name)
  end

  it 'admins should be able to download a csv of the global list of api keys' do
    api_key1 = create(:api_key, account_id: @user.id)
    api_key2 = create(:api_key, account_id: @admin.id)
    login_as @admin
    get :index, format: :csv
    must_respond_with :ok
    response.body.must_match('Open Hub account,Application Name')
    response.body.must_match(api_key1.oauth_application.name)
    response.body.must_match(api_key2.oauth_application.name)
    response.headers['Content-Type'].must_include('text/csv')
    response.headers['Content-Type'].must_include('text/csv')
    response.headers['Content-Disposition'].must_include('attachment')
    response.headers['Content-Disposition'].must_include('api_keys_report.csv')
  end

  # new action
  it 'new should let admins edit daily limit' do
    login_as @admin
    get :new, account_id: @admin.id
    must_respond_with :ok
    response.body.must_match('api_key_daily_limit')
  end

  it 'new should not let users edit daily limit' do
    login_as @user
    get :new, account_id: @user.id
    must_respond_with :ok
    response.body.wont_match('api_key_daily_limit')
  end

  it 'new should not let users who have enough keys make more' do
    (1..ApiKey::KEY_LIMIT_PER_ACCOUNT).each { |i| create(:api_key, account_id: @user.id, key: "max_keys_test_#{i}") }
    login_as @user
    get :new, account_id: @user.id
    must_respond_with 302
  end

  it 'new should understand the me user for logged users' do
    login_as @user
    get :new, account_id: 'me'
    must_respond_with :ok
    response.body.must_match 'foo'
  end

  it 'new should understand the me user' do
    get :new, account_id: 'me'
    must_redirect_to new_session_path
  end

  # create action
  it 'create with valid parameters should create an api key' do
    login_as @user
    post :create, account_id: @user.id, api_key: { name: 'Name',
                                                   description: 'It was the best of times.',
                                                   terms: '1' }
    must_respond_with :found
    ApiKey.where(account_id: @user.id, description: 'It was the best of times.').first.must_be :present?
  end

  it 'create requires accepting the terms of service' do
    login_as @user
    post :create, account_id: @user.id, api_key: { name: 'Name',
                                                   description: 'I do not accept those terms!',
                                                   terms: '0' }
    must_respond_with :bad_request
    response.body.must_match(I18n.t(:must_accept_terms))
    ApiKey.where(account_id: @user.id, description: 'I do not accept those terms!').first.wont_be :present?
  end

  # edit action
  it 'edit should populate the form' do
    api_key = create(:api_key, account_id: @user.id, description: 'A pre-existing API Key.')
    login_as @user
    get :edit, account_id: @user.id, id: api_key.id
    must_respond_with :ok
    response.body.must_match('A pre-existing API Key.')
  end

  it 'edit should 404 attempting to edit a non-existant api key' do
    login_as @user
    get :edit, account_id: @user.id, id: 9876
    must_respond_with :not_found
  end

  # update action
  it 'update should populate the form' do
    api_key = create(:api_key, account_id: @user.id, description: 'My old crufty API Key.')
    login_as @user
    put :update, account_id: @user.id, id: api_key.id, api_key: { name: 'Name',
                                                                  description: 'Repolished key!',
                                                                  terms: '1' }
    must_respond_with 302
    api_key.reload
    api_key.description.must_equal 'Repolished key!'
  end

  it 'update does not allow unaccepting the terms' do
    api_key = create(:api_key, account_id: @user.id, description: 'My previous API Key.')
    login_as @user
    put :update, account_id: @user.id, id: api_key.id, api_key: { name: 'Name',
                                                                  description: 'I cleverly unaccept now!',
                                                                  terms: '0' }
    must_respond_with :bad_request
    api_key.reload
    api_key.description.must_equal 'My previous API Key.'
  end

  # destroy action
  it 'destroy should remove the api key from the db' do
    api_key = create(:api_key, account_id: @user.id, description: 'My doomed key.')
    login_as @user
    delete :destroy, account_id: @user.id, id: api_key.id
    must_respond_with 302
    ApiKey.where(account_id: @user.id, description: 'My doomed key.').first.wont_be :present?
  end

  # destroy action
  it 'destroy gracefully handle error cconditions' do
    api_key = create(:api_key, account_id: @user.id, description: 'My safe key.')
    ApiKey.any_instance.stubs(:destroy).returns(false)
    login_as @user
    delete :destroy, account_id: @user.id, id: api_key.id
    must_respond_with 302
    ApiKey.where(account_id: @user.id, description: 'My safe key.').first.must_be :present?
  end
end
