class PermissionsController < ApplicationController
  helper ProjectsHelper

  before_action :session_required, :redirect_unverified_account, only: :update
  before_action :set_project_or_fail
  before_action :find_model
  before_action :require_manage_authorization, only: :update
  before_action :show_permissions_alert, only: :show
  before_action :project_context, only: [:show, :update]

  def update
    if find_model.update(model_params)
      flash.now[:success] = t('.success')
      render :show, status: :ok
    else
      flash.now[:error] = t('.error')
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_model
    @permission = @project.permission || Permission.new(target: @project)
    @permission.tap { |p| p.editor_account = current_user }
  end

  def model_params
    params.require(:permission).permit(:remainder)
  end

  def require_manage_authorization
    return if current_user_can_manage?
    flash.now[:error] = t(:not_authorized)
    render :show, status: :unauthorized
  end
end
