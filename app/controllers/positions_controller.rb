# rubocop:disable Metrics/ClassLength
require 'will_paginate/array'
class PositionsController < ApplicationController
  helper ProjectsHelper
  helper PositionsHelper
  include PositionFilters

  def new
    @position = Position.new
  end

  def update
    Position.transaction do
      @position.language_experiences.delete_all
      @position.update!(position_params)
    end
    redirect_to account_positions_path(@account)
  rescue => e
    flash.now[:error] = e.message unless e.is_a?(ActiveRecord::RecordInvalid)
    render :edit
  end

  def create
    @position = @account.positions.create!(position_params)
    flash_invite_success_if_needed
    redirect_to account_positions_path(@account)
  rescue
    @position = Position.new
    render :new, status: :unprocessable_entity
  end

  def show
  end

  def destroy
    if @position.destroy
      redirect_to account_positions_path, notice: t('destroy.success')
    else
      redirect_to :back, flash: { error: t('destroy.failure') }
    end
  end

  def index
    @positions = @account.position_core.ordered.paginate(page: page_param, per_page: 10)
  end

  def commits_compound_spark
    @project = @position.project
    @name_fact = ContributorFact.includes(:name).where(analysis_id: @project.best_analysis_id,
                                                       name_id: @position.name_id).first
    spark_image = Spark::CompoundSpark.new(@name_fact.monthly_commits(11), max_value: 50).render.to_blob
    send_data spark_image, type: 'image/png', filename: 'position_commits_compound_spark.png', disposition: 'inline'
  end

  def one_click_create
    pos_or_alias_obj = current_user.position_core.ensure_position_or_alias!(@project, @name)
    return redirect_to_new_position_path unless pos_or_alias_obj

    if pos_or_alias_obj.is_a?(Alias)
      flash_msg = t('.alias', name: @name.name, preferred_name: pos_or_alias_obj.preferred_name.name)
    else
      flash_msg = t('.position', name: @name.name)
    end

    redirect_to account_positions_path(current_user), flash: { success: flash_msg }
  end

  private

  def flash_invite_success_if_needed
    flash[:success] = t('.invite_success') if params[:invite].present? && @account.created_at > 1.day.ago
  end

  def redirect_to_new_position_path
    redirect_to new_account_position_path(current_user, committer_name: @name.name,
                                                        project_name: @project.name,
                                                        invite: params[:invite]),
                flash: { success: t('positions.one_click_create.new_position', name: @name.name) }
  end

  def params_id_is_total?
    params[:id].to_s.downcase == 'total'
  end

  def position_params
    params.require(:position)
      .permit(:project_oss, :committer_name, :title, :organization_id, :organization_name,
              :affiliation_type, :description, :start_date, :stop_date, :ongoing, :invite,
              language_exp: [], project_experiences_attributes: [:project_name, :_destroy, :id])
  end
end
