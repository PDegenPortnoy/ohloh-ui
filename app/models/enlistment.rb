class Enlistment < ActiveRecord::Base
  belongs_to :repository
  belongs_to :project
  acts_as_editable editable_attributes: [:ignore]
  acts_as_protected parent: :project
  scope :sort_by_url, ->{ order('projects.name, repositories.url, repositories.module_name')}
  scope :sort_by_project, ->{order('projects.name, repositories.url, repositories.module_name') }
  scope :sort_by_type, ->{order('repositories.type, repositories.url, repositories.module_name') }
  scope :sort_by_module_name, ->{ order('repositories.module_name, repository_ides.url') }

  scope :with_url_like, ->(like){ (like.nil? || like.empty?) ? where('TRUE') : where('lower(repositories.url) LIKE :query', query: "%#{ like.downcase }%") }
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

  # TODO: Ensure forge and job 
  # end

  def revive_or_create
    deleted_enlistment = Enlistment.find_by(project_id: project_id, deleted: true)
    return save unless deleted_enlistment
    CreateEdit.where(target: deleted_enlistment).first.redo!(editor_account)
    deleted_enlistment.editor_account = editor_account
    deleted_enlistment.update_attributes(ignore: ignore)
  end

  def ignore_examples
    examples = []
    if repository.best_code_set
      examples = repository.best_code_set.fyles.first(3).map(&:name).sort
    end
    examples
  end

  def analysis_sloc_set
    return nil unless project.best_analysis
    analysis_sloc_sets = project.best_analysis.analysis_sloc_sets
    analysis_sloc_sets.joins("INNER JOIN sloc_sets ON analysis_sloc_sets.sloc_set_id = sloc_sets.id INNER JOIN repositories ON repositories.best_code_set_id = sloc_sets.code_set_id AND repositories.id = #{repository_id}").limit(1)
  end
 
end