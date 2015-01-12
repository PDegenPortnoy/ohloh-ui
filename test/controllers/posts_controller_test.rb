require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  fixtures :accounts, :forums, :topics, :posts
  
  def setup
    @forum = forums(:rails)
    @topic = topics(:pdi)
    @account = accounts(:user)
    @post = posts(:pdi)
    ActionMailer::Base.deliveries.clear
  end

  test "index" do
    get :index, forum_id: @forum.id, topic_id: @topic.id
    assert_response :success
  end

  test "create action: a user creates a post for the first time" do
    forum = forums(:broken_forum_topic_no_posts)
    topic = topics(:broken_topic_no_posts)
    account = accounts(:admin)
    assert_difference(['Post.count','ActionMailer::Base.deliveries.size'], 1) do
      post :create, forum_id: forum.id, topic_id: topic.id, post: {body: "I am the same user.", account_id: topic.account.id } 
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [account.email], email.to #Admin Allen
    assert_equal "Post successfully created", email.subject
    assert_redirected_to forum_topic_path(forum.id, topic.id)
  end

  test "create action: user2 replying to user1 receives a creation email while user1 receives a reply email" do
    forum = forums(:javascript)
    topic = topics(:javascript)
    user2 = accounts(:user)
    assert_difference(['ActionMailer::Base.deliveries.size'], 2) do
      post :create, forum_id: forum.id, topic_id: topic.id, post: {body: "Post reply gets sent to Joe. Post creation gets sent to user Luckey", account_id: user2.id}
    end
    email = ActionMailer::Base.deliveries
    assert_equal [topic.account.email], email.first.to 
    assert_equal "Someone has responded to your post", email.first.subject
    assert_equal [user2.email], email.last.to
    assert_equal "Post successfully created", email.last.subject
    assert_redirected_to forum_topic_path(forum.id, topic.id)
  end

  test "create action: Users who have posted more than once on a topic receive only one email notification" do
    last_user = accounts(:joe)
    assert_difference(['ActionMailer::Base.deliveries.size'], 3) do
      post :create, forum_id: @forum.id, topic_id: @topic.id, post: {body: "This post should trigger a cascade of emails being sent to all preceding users", account_id: last_user.id }
    end
    email = ActionMailer::Base.deliveries
    #First email
    assert_equal [accounts(:admin).email], email.first.to 
    assert_equal "Someone has responded to your post", email.first.subject
    #Second email
    assert_equal [accounts(:user).email], email[1].to
    assert_equal "Someone has responded to your post", email[1].subject
    #Third email
    assert_equal [last_user.email], email.last.to
    assert_equal "Post successfully created", email.last.subject
    assert_redirected_to forum_topic_path(@forum.id, @topic.id)
  end

  test "create action: A user who replies to his own post will not receive a post notification email while everyone else does." do
    last_user = accounts(:admin)
    assert_difference(['ActionMailer::Base.deliveries.size'], 2) do
      post :create, forum_id: @forum.id, topic_id: @topic.id, post: {body: "Admin allen replies to his own post", account_id: last_user.id }
    end
    email = ActionMailer::Base.deliveries
    assert_equal [accounts(:user).email], email.first.to
    assert_equal "Someone has responded to your post", email.first.subject
    #Third email
    assert_equal [last_user.email], email.last.to
    assert_equal "Post successfully created", email.last.subject
    assert_redirected_to forum_topic_path(@forum.id, @topic.id)
  end

  test "edit" do
    get :edit, forum_id: @forum.id, topic_id: @topic.id, id: @post.id
    assert_response :success
  end

  test "update a post" do
    put :update, forum_id: @forum.id, topic_id: @topic.id, id: @post.id, post: {body: "Updating the body"}
    @post.reload
    assert_equal "Updating the body", @post.body
    assert_redirected_to forum_topic_path(@forum.id, @topic.id)
  end

  test "delete a post" do
    assert_difference('Post.count', -1) do
      delete :destroy, forum_id: @forum.id, topic_id: @topic.id, id: @post.id
    end
    assert_redirected_to forum_topic_path(@forum.id, @topic.id)
  end
end