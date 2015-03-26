class EnlistmentsController < SettingsController
	before_action :session_required,:only => [:create, :new, :destroy, :edit, :update]
	before_action :set_project
  before_action :set_enlistment, only: [:edit, :update, :destroy, :show, :create]

  # TODO: Ensure forge and job 
  # rewrite create
  # layer_params
  # sorted_filtered
  # end


  def index
    @enlistments = @project.enlistments.all
    respond_to do |format|
			format.html
			format.js   { render :partial => "items_list", :layout => false }
			format.xml  { render :layout => false }
		end

  end

  def new
    @enlistment = Enlistment.new
  end

  def create
  end

  def show
    respond_to do |format|
			format.xml { render :layout => false }
		end
  end

  def edit
  end

  def update
    if @enlistment.update(enlistment_params)
      redirect_to project_enlistments_path(@project), flash: { success: t('.success') }
    else
      render :edit, status: 422
    end
  end

	def destroy
    @enlistment.revive_or_create
    flash[:success] = "Code location was removed from #{@project.name} successfully."
		redirect_to project_enlistments_url(:project_id => @enlistment.project_id)
	end

	private

	def set_enlistment
    @enlistment = @project.enlistments.find(params[:id])
    @enlistment.editor_account = current_user
  end

  def set_project
    @project = Project.from_param(params[:project_id]).first
  end

  def enlistment_params
    params.require(:enlistment).permit([:ignore, :project_id])
  end

end
