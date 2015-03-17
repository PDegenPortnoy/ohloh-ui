require 'test_helper'

class EnlistmentTest < ActiveSupport::TestCase
  it '#enlist_project_in_repository creates an enlistment' do
    proj = create(:project)
    repository = create(:repository)
    r = Enlistment.enlist_project_in_repository(create(:account), proj, repository, 'stop ignoring me!')
    r.project_id.must_equal proj.id
    r.repository_id.must_equal repository.id
    r.ignore.must_equal 'stop ignoring me!'
  end

  it '#enlist_project_in_repository undeletes old enlistment' do
    proj = create(:project)
    repository = create(:repository)
    r1 = Enlistment.enlist_project_in_repository(create(:account), proj, repository)
    r1.destroy
    r1.reload
    r1.deleted.must_equal true
    r2 = Enlistment.enlist_project_in_repository(create(:account), proj, repository)
    r2.deleted.must_equal false
    r1.id.must_equal r2.id
  end

  it 'must revive or create deleted enlistments' do
    enlistment = create(:enlistment, project: projects(:linux))
    enlistment.destroy
    ignore = "ignore"
    new_enlistment = build(:enlistment, ignore: ignore, project_id: enlistment.project_id )
    new_enlistment.editor_account = create(:account) 
    assert_no_difference('Enlistment.count') do
      new_enlistment.revive_or_create
    end

    deleted_enlistment = Enlistment.where(id: enlistment.id).first
    deleted_enlistment.ignore.must_equal ignore
  end

  it 'should null ignore_examples' do
    proj = create(:project)
    repository = create(:repository)
    enlistment = Enlistment.enlist_project_in_repository(create(:account), proj, repository, 'stop ignoring me!')
    enlistment.ignore_examples.must_equal []
  end
  it 'should return files from ignore_examples' do
    enlistment = create(:enlistment_with_code_set)
    enlistment.ignore_examples.must_equal ["test.c"]
  end

  it 'should return files from ignore_examples' do
    enlistment = create(:enlistment_with_code_set)
    enlistment.ignore_examples.must_equal ["test.c"]
  end
  it 'should return sloc_sets' do
    enlistment = create(:enlistment)
    enlistment.analysis_sloc_set.must_equal []
  end

end
