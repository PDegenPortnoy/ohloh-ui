class StackBuilderController < ApplicationController
  before_action :setup_stack, only: [:show, :reset]
  before_action :setup_account, only: [:show, :reset]
  before_action :stack_authorized, except: :show
  before_action :create_stack_ignores, only: [:show, :recommendations]

  helper :projects

  def show
    redirect_to stack_path(@stack.id)
  end

  def recommendations
    suggestions = render_to_string partial: 'stacks/small_suggestion.html.haml', collection: @stack.suggest_projects(5)
    render json: { recommendations: suggestions }
  end

  def reset
    @stack.reset
    @stack = Stack.where(session_id: request.session_options[:id]).first_or_create if params[:init] && @stack.sandbox?
    @stack.reinitialize(params[:init])
    redirect_to stack_path(@stack.id)
  end

  private

  def stack_authorized
    fail ParamNotFound if @current_account != @stack.account && @stack.sandbox?
  end

  def setup_stack
    stack_id = params[:stack_id] || params[:id]
    if stack_id == 'sandbox'
      @stack = Stack.where(session_id: request.session_options[:id]).first_or_create
    else
      @stack = Stack.find(stack_id)
    end
  end

  def setup_account
    @account = Account.find_by(id: params[:account_id]) if params[:account_id]
    @account ||= @stack.account
    @sandbox = @stack.sandbox?
    redirect_to account_path(@account) if @account && @account != @stack.account
  end

  def create_stack_ignores
    return if params[:ignore].blank?
    params[:ignore].split(',').compact.each do |project_id|
      @stack.stack_ignores.create!(project_id: project_id.to_i)
    end
  end
end
