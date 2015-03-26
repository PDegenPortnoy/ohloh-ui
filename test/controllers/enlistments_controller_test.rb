require 'test_helper'
describe 'EnlistmentsControllerTest' do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:user) { create(:account) }

  it 'index' do
    get :index, project_id: project.url_name
    must_respond_with :success
  end

  it 'new' do
    login_as(admin)
    get :new, project_id: project.url_name
    must_respond_with :success
  end

  it 'edit' do
    enlistment = create(:enlistment, project: project)
    login_as(admin)
    get :edit, project_id: project.url_name, id: enlistment.id
    must_respond_with :success
  end

  it 'the enlistment is being updated' do
  	enlistment = create(:enlistment, project: project)
    login_as(admin)
    put :update, id: enlistment.id, project_id: project.url_name, enlistment: { ignore: nil }
    must_redirect_to project_enlistments_path(project)
  end

  it 'show' do
    login_as create(:admin)
    enlistment = create(:enlistment, project: project)
    get :show, id: enlistment
    must_respond_with :ok
    response.body.wont_include('flash-msg')
    #must_select 'input[disabled="disabled"]', false
  end


end