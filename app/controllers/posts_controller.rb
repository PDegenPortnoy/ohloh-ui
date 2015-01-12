require 'test_helper'

class PostsController < ApplicationController
  before_action :find_forum_and_topic_records
  before_action :find_post_record, only: [:edit,:update,:destroy]
  
  def index
    @posts = @topic.posts
  end

  def create
    @post = @topic.posts.build(post_params)
    respond_to do |format|
      if @post.save 
        post_notification(@post)
        format.html { redirect_to forum_topic_path(@forum,@topic), flash: { success: t('.success') } }
      else
        format.html { redirect_to forum_topic_path(@forum,@topic), flash: { error: t('.error') } }
      end
    end
  end

  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to forum_topic_path(@forum, @topic), flash: { success: t('.success') } }
      else
        format.html { redirect_to forum_topic_path(@forum, @topic), flash: { error: t('.error') } }
      end
    end
  end

  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to forum_topic_path(@forum, @topic) }
    end
  end

  private

  def post_notification(post)
    @user_who_began_topic = post.topic.account
    @user_who_replied = post.account
    @topic = post.topic
    if @user_who_replied != @user_who_began_topic 
      find_collection_of_users(post)
      send_reply_emails_to_everyone(@all_users_preceding_the_last_user.uniq!)
      send_creation_email
    else
      find_collection_of_users(post)
      @all_users_preceding_the_last_user = @all_users_preceding_the_last_user.reject { |user| user.id == @user_who_replied.id }
      send_reply_emails_to_everyone(@all_users_preceding_the_last_user)
      send_creation_email
    end
  end

  def find_collection_of_users(post)
    @all_users_preceding_the_last_user = post.topic.posts.map { |posts| posts.account }
    @all_users_preceding_the_last_user.pop
    @all_users_preceding_the_last_user
  end

  def send_reply_emails_to_everyone(users)
    @all_users_preceding_the_last_user.each do |user|
      PostNotifier.post_replied_notification(user, @user_who_replied, @topic).deliver 
    end
  end

  def send_creation_email
    PostNotifier.post_creation_notification(@user_who_replied, @topic).deliver
  end

  def find_post_record
    find_forum_and_topic_records
    @post = @topic.posts.find_by(id: params[:id])
  end

  def find_forum_and_topic_records
    @forum = Forum.find_by(id: params[:forum_id])
    @topic = @forum.topics.find_by(id: params[:topic_id])
  end

  def post_params
    params.require(:post).permit(:topic_id, :account_id, :body)
  end
end