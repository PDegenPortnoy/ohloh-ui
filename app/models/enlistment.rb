class Enlistment < ActiveRecord::Base
  belongs_to :repository
  belongs_to :project

  acts_as_editable editable_attributes: [:ignore]
  acts_as_protected parent: :project
  scope :sort_by_url, ->{ order('projects.name, repositories.url, repositories.module_name')}
  scope :sort_by_project, ->{order('projects.name, repositories.url, repositories.module_name') }
  scope :sort_by_type, ->{order('repositories.type, repositories.url, repositories.module_name') }
  scope :sort_by_module_name, ->{order('repositories.module_name, repositories.url') }
  scope :filter_by, lambda { |query|
    includes(:project, :repository)
      .references(:all)
      .where('projects.name ilike :query or repositories.url ilike :query or' \
            ' repositories.module_name ilike :query or repositories.type ilike :query' \
            ' or repositories.branch_name ilike :query', query: "%#{query}%") if query
  }

  class << self
    def enlist_project_in_repository(editor_account, project, repository, ignore = nil)
      enlistment = Enlistment.where(project_id: project.id, repository_id: repository.id).first_or_initialize
      transaction do
        enlistment.editor_account = editor_account
        enlistment.assign_attributes(ignore: ignore)
        enlistment.save
        CreateEdit.where(target: enlistment).first.redo!(editor_account) if enlistment.deleted
      end
      enlistment.reload
    end
  end

  delegate 'failed?', :to => :repository

=begin  
  def explain_yourself(edit) # not required as i didn't find act_as editable with explaination
  end

  def ensure_forge_and_job # i ahven't seen any after_save calbacks here 
  end

  def self.with_url_like(like) # not used anywhere
  end

  def analysis_sloc_set #CodeSet model not found
  end
  def ignore_examples not used anywhere
  end
=end  
end
