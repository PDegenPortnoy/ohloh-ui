
class AuthorizationController < ApplicationController
  before_filter :login_required, :except => [:request_token, :access_token, :test_request]
  before_filter :login_or_oauth_required,:only => [:test_request]
  before_action :verify_oauth_consumer_signature, :only => [:request_token]
  before_filter :verify_oauth_request_token, :only => [:access_token]
  before_filter :must_own_account, :only => [:revoke]

  def request_token
    @token = current_api_key.create_request_token if current_api_key
    if @token
      render :text => @token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def access_token
    @token = current_token.exchange! if current_token
    if @token
      render :text => @token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def revoke
    @account ||= Account.find(params[:account_id])
    authorization = @account.authorizations.find_by_id(params[:id])
    if authorization
      authorization.invalidate!
      flash[:success] = "You have successfully revoked the authorization for #{CGI::escapeHTML authorization.api_key.name}"
    end
    redirect_to edit_account_privacy_path(@account)
  end

  def test_request
    render :text=>params.collect{|k,v|"#{k}=#{v}"}.join("&")
  end

  def current_model_name
    'Account'
  end

  def current_object
    @account ||= Account.find(params[:account_id])
  end

  def authorize
    @authorization=RequestToken.find_by_token params[:oauth_token]
    raise ActiveRecord::RecordNotFound unless @authorization

    unless @authorization.invalidated?
      if request.post?
        if params[:authorize]=='1'
          @authorization.authorize!(current_account)
          redirect_url = params[:oauth_callback] || @authorization.api_key.callback_url
          if redirect_url
            redirect_to redirect_url + "?oauth_token=#{@authorization.token}"
          else
            flash[:success] = "You have authorized #{CGI::escapeHTML @authorization.api_key.name} to access your Open Hub account."
            redirect_to account_authorizations_path(current_account)
          end
        else
          @authorization.invalidate!
          flash[:notice] = "You have denied access to application #{CGI::escapeHTML @authorization.api_key.name}"
          redirect_to account_authorizations_path(current_account)
        end
      end
    else
      redirect_to account_authorizations_path(current_account)
    end
  end
end
