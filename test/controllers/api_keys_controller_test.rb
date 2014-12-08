require 'test_helper'

class ApiKeysControllerTest < ActionController::TestCase
  fixtures :accounts

  # index action
  test 'admins should be able to look at the global list of api keys' do
    login_as accounts(:admin)
    get :index
    assert_response :ok
  end

  test 'unlogged in users should not be able to look at the global list of api keys' do
    login_as nil
    get :index
    assert_response :unauthorized
  end

  test 'normal users should not be able to look at the global list of api keys' do
    login_as accounts(:user)
    get :index
    assert_response :unauthorized
  end

  test 'index page should find models whose name match the "q" parameter' do
    api_key1 = create(:api_key, name: 'foobar')
    api_key2 = create(:api_key, name: 'goobaz')
    login_as accounts(:admin)
    get :index, q: 'foobar'
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'index page should find models whose description match the "q" parameter' do
    api_key1 = create(:api_key, description: 'foobar')
    api_key2 = create(:api_key, description: 'goobaz')
    login_as accounts(:admin)
    get :index, q: 'foobar'
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'index page should find models whose key match the "q" parameter' do
    api_key1 = create(:api_key, key: 'foobar')
    api_key2 = create(:api_key, key: 'goobaz')
    login_as accounts(:admin)
    get :index, q: 'foobar'
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'index page should find models whose account name match the "q" parameter' do
    api_key1 = create(:api_key, account_id: accounts(:user).id)
    api_key2 = create(:api_key, account_id: accounts(:admin).id)
    login_as accounts(:admin)
    get :index, q: 'user'
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'index page should accept "query" in place of "q" as a parameter' do
    api_key1 = create(:api_key, name: 'foobar')
    api_key2 = create(:api_key, name: 'goobaz')
    login_as accounts(:admin)
    get :index, query: 'foobar'
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'index page should honor the sort order "most_recent_request"' do
    api_key1 = create(:api_key, last_access_at: Time.now)
    api_key2 = create(:api_key, last_access_at: Time.now - 1.day)
    api_key3 = create(:api_key, last_access_at: Time.now + 1.day)
    login_as accounts(:admin)
    get :index, sort: 'most_recent_request'
    assert_response :ok
    assert(/#{api_key3.name}.*#{api_key1.name}.*#{api_key2.name}/m.match(response.body))
  end

  test 'index page should honor the sort order "most_requests_today"' do
    api_key1 = create(:api_key, daily_count: 11)
    api_key2 = create(:api_key, daily_count: 10)
    api_key3 = create(:api_key, daily_count: 12)
    login_as accounts(:admin)
    get :index, sort: 'most_requests_today'
    assert_response :ok
    assert(/#{api_key3.name}.*#{api_key1.name}.*#{api_key2.name}/m.match(response.body))
  end

  test 'index page should honor the sort order "most_requests"' do
    api_key1 = create(:api_key, total_count: 11)
    api_key2 = create(:api_key, total_count: 10)
    api_key3 = create(:api_key, total_count: 12)
    login_as accounts(:admin)
    get :index, sort: 'most_requests'
    assert_response :ok
    assert(/#{api_key3.name}.*#{api_key1.name}.*#{api_key2.name}/m.match(response.body))
  end

  test 'index page should honor the sort order "newest"' do
    api_key1 = create(:api_key, created_at: Time.now)
    api_key2 = create(:api_key, created_at: Time.now - 1.day)
    api_key3 = create(:api_key, created_at: Time.now + 1.day)
    login_as accounts(:admin)
    get :index, sort: 'newest'
    assert_response :ok
    assert(/#{api_key3.name}.*#{api_key1.name}.*#{api_key2.name}/m.match(response.body))
  end

  test 'index page should honor the sort order "oldest"' do
    api_key1 = create(:api_key, created_at: Time.now)
    api_key2 = create(:api_key, created_at: Time.now - 1.day)
    api_key3 = create(:api_key, created_at: Time.now + 1.day)
    login_as accounts(:admin)
    get :index, sort: 'oldest'
    assert_response :ok
    assert(/#{api_key2.name}.*#{api_key1.name}.*#{api_key3.name}/m.match(response.body))
  end

  test 'index page should honor the sort order "account_name"' do
    api_key1 = create(:api_key, account_id: accounts(:user).id)
    api_key2 = create(:api_key, account_id: accounts(:admin).id)
    login_as accounts(:admin)
    get :index, sort: 'account_name'
    assert_response :ok
    assert(/#{api_key2.name}.*#{api_key1.name}/m.match(response.body))
  end

  test 'index page should assume "newest" when the sort parameter is unsupported' do
    api_key1 = create(:api_key, created_at: Time.now)
    api_key2 = create(:api_key, created_at: Time.now - 1.day)
    api_key3 = create(:api_key, created_at: Time.now + 1.day)
    login_as accounts(:admin)
    get :index, sort: 'I_am_a_banana!'
    assert_response :ok
    assert(/#{api_key3.name}.*#{api_key1.name}.*#{api_key2.name}/m.match(response.body))
  end

  test 'admins should be able to look at the api keys of someone else' do
    login_as accounts(:admin)
    get :index, account_id: accounts(:user).id
    assert_response :ok
  end

  test 'unlogged in users should not be able to look at the api keys of a user' do
    login_as nil
    get :index, account_id: accounts(:user).id
    assert_response :unauthorized
  end

  test 'normal users should be able to look at their own api keys' do
    login_as accounts(:user)
    get :index, account_id: accounts(:user).id
    assert_response :ok
  end

  test 'normal users should not be able to look at someone elses api keys' do
    login_as accounts(:user)
    get :index, account_id: accounts(:admin).id
    assert_response :unauthorized
  end

  test 'normal users should see their api keys, but not others' do
    api_key1 = create(:api_key, account_id: accounts(:user).id)
    api_key2 = create(:api_key, account_id: accounts(:admin).id)
    login_as accounts(:user)
    get :index, account_id: accounts(:user).id
    assert_response :ok
    assert response.body.match(api_key1.name)
    assert !response.body.match(api_key2.name)
  end

  test 'admins should be able to download a csv of the global list of api keys' do
    api_key1 = create(:api_key, account_id: accounts(:user).id)
    api_key2 = create(:api_key, account_id: accounts(:admin).id)
    login_as accounts(:admin)
    get :index, format: :csv
    assert_response :ok
    assert response.body.match('Open Hub account,Application Name')
    assert response.body.match(api_key1.name)
    assert response.body.match(api_key2.name)
    assert response.headers['Content-Type'].include? 'text/csv'
    assert response.headers['Content-Disposition'].include? 'attachment'
    assert response.headers['Content-Disposition'].include? 'api_keys_report.csv'
  end

  # new action
  test 'new should let admins edit daily limit' do
    login_as accounts(:admin)
    get :new, account_id: accounts(:admin).id
    assert_response :ok
    assert response.body.match('api_key_daily_limit')
  end

  test 'new should not let users edit daily limit' do
    login_as accounts(:user)
    get :new, account_id: accounts(:user).id
    assert_response :ok
    assert !response.body.match('api_key_daily_limit')
  end

  test 'new should not let users who have enough keys make more' do
    (1..ApiKey::KEY_LIMIT_PER_ACCOUNT).each { create(:api_key, account_id: accounts(:user).id) }
    login_as accounts(:user)
    get :new, account_id: accounts(:user).id
    assert_response 302
  end

  # create action
  test 'create with valid parameters should create an api key' do
    login_as accounts(:user)
    post :create, account_id: accounts(:user).id, api_key: { name: 'Name',
                                                             description: 'It was the best of times.',
                                                             terms: '1' }
    assert_response :found
    assert ApiKey.where(account_id: accounts(:user).id, description: 'It was the best of times.').first
  end

  test 'create requires accepting the terms of service' do
    login_as accounts(:user)
    post :create, account_id: accounts(:user).id, api_key: { name: 'Name',
                                                             description: 'I do not accept those terms!',
                                                             terms: '0' }
    assert_response :bad_request
    assert response.body.match(I18n.t(:must_accept_terms))
    assert !ApiKey.where(account_id: accounts(:user).id, description: 'I do not accept those terms!').first
  end

  # edit action
  test 'edit should populate the form' do
    api_key = create(:api_key, account_id: accounts(:user).id, description: 'A pre-existing API Key.')
    login_as accounts(:user)
    get :edit, account_id: accounts(:user).id, id: api_key.id
    assert_response :ok
    assert response.body.match('A pre-existing API Key.')
  end

  test 'edit should 404 attempting to edit a non-existant api key' do
    login_as accounts(:user)
    get :edit, account_id: accounts(:user).id, id: 9876
    assert_response :not_found
  end

  # update action
  test 'update should populate the form' do
    api_key = create(:api_key, account_id: accounts(:user).id, description: 'My old crufty API Key.')
    login_as accounts(:user)
    put :update, account_id: accounts(:user).id, id: api_key.id, api_key: { name: 'Name',
                                                                            description: 'Repolished key!',
                                                                            terms: '1' }
    assert_response 302
    api_key.reload
    assert_equal 'Repolished key!', api_key.description
  end

  test 'update does not allow unaccepting the terms' do
    api_key = create(:api_key, account_id: accounts(:user).id, description: 'My previous API Key.')
    login_as accounts(:user)
    put :update, account_id: accounts(:user).id, id: api_key.id, api_key: { name: 'Name',
                                                                            description: 'I cleverly unaccept now!',
                                                                            terms: '0' }
    assert_response :bad_request
    api_key.reload
    assert_equal 'My previous API Key.', api_key.description
  end

  # destroy action
  test 'destroy should remove the api key from the db' do
    api_key = create(:api_key, account_id: accounts(:user).id, description: 'My doomed key.')
    login_as accounts(:user)
    delete :destroy, account_id: accounts(:user).id, id: api_key.id
    assert_response 302
    assert !ApiKey.where(account_id: accounts(:user).id, description: 'My doomed key.').first
  end
end
