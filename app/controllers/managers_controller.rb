class ManagersController < ApplicationController
  before_action :session_required, except: :index
  before_action :find_parent
  before_action :find_manages, only: :index
  before_action :find_manage, except: :index
  before_action :admin_session_required, only: [:new, :create, :edit, :update], if: -> { @parent.is_a? Organization }

  def new
    @manage ||= Manage.new
  end

  def create
    @manage ||= Manage.new
    @manage.assign_attributes(model_params.merge(target: @parent, account: current_user))
    if @manage.save
      redirect_to_index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return render_unauthorized unless current_user_can_manage?
  end

  def update
    return render_unauthorized unless current_user_can_manage?
    if @manage.update_attributes(model_params)
      flash[:notice] = t '.notice'
      redirect_to_index
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    return render_unauthorized unless current_user_can_manage?
    if @manage
      @manage.approve!(current_user)
      flash[:success] = t '.notice', name: ERB::Util.html_escape(@manage.account.name)
    end
    redirect_to_index
  end

  def reject
    return render_unauthorized unless current_user_can_manage_or_self?
    if @manage
      @manage.destroy_by!(current_user)
      flash[:notice] = t '.notice', name: ERB::Util.html_escape(@manage.account.name),
                                    target: ERB::Util.html_escape(@parent.name)
    end
    redirect_to_index
  end

  protected

  def current_user_can_manage?
    return true if current_user_is_admin?
    logged_in? && @parent && @parent.active_managers.include?(current_user)
  end
  helper_method :current_user_can_manage?

  def current_user_can_manage_or_self?
    current_user_can_manage? || @manage.account == current_user
  end

  private

  def model_params
    params.require(:manage).permit(:message)
  end

  def find_manages
    @manages = Manage.where(target: @parent, deleted_by: nil).to_a
  end

  def find_manage
    account_name = params[:id] || current_user.login
    @manage = Manage.not_denied.for_account(Account.from_param(account_name).first!).first
  rescue ActiveRecord::RecordNotFound
    raise ParamRecordNotFound
  end

  def find_parent
    @parent = if params[:project_id]
                Project.from_param(params[:project_id]).first!
              else
                Organization.from_param(params[:organization_id]).first!
              end
  rescue ActiveRecord::RecordNotFound
    raise ParamRecordNotFound
  end

  def redirect_to_index
    redirect_to view_context.parent_managers_path(@parent)
  end
end
