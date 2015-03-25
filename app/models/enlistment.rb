class Enlistment < ActiveRecord::Base
  belongs_to :repository
  belongs_to :project

  acts_as_editable editable_attributes: [:ignore]
  acts_as_protected parent: :project

  after_save :ensure_forge_and_job
  # after_save { |e| e.project.save }

  validates :ignore, length: { maximum: 500 }, allow_nil: true

  delegate 'failed?', to: :repository
# TODO: 
  # Ensure forge and job
  # explain_yourself
  # refactor analysis_sloc_set
  # after_save results failing enlist_project_in_repository
# end

  scope :sort_by_url, -> { order('projects.name, repositories.url, repositories.module_name') }
  scope :sort_by_project, -> { order('projects.name, repositories.url, repositories.module_name') }
  scope :sort_by_type, -> { order('repositories.type, repositories.url, repositories.module_name') }
  scope :sort_by_module_name, -> { order('repositories.module_name, repository_ides.url') }
  
  scope :filter_by, lambda { |query|
    includes(:project, :repository)
      .references(:all)
      .where('lower(projects.name) like :query or lower(repositories.url) like :query or' \
            ' lower(repositories.module_name) like :query or lower(repositories.type) like :query' \
            ' or lower(repositories.branch_name) like :query', query: "%#{query.downcase}%") if query
  }

  def ignore_examples
   (repository.best_code_set)? repository.best_code_set.fyles.pluck(:name).first(3).sort : []
     # (repository.best_code_set)? Enlistment.where(id: id).includes(repository: [best_code_set: :fyles]).pluck(:name).first(3) : []
      # NOTE: Sort has to replace with inner psql query and i have used LEFT OUTER JOIN to meet requirement
  end

  def analysis_sloc_set
    return nil unless project.best_analysis
    analysis_sloc_sets = project.best_analysis.analysis_sloc_sets
    analysis_sloc_sets.joins("INNER JOIN sloc_sets ON analysis_sloc_sets.sloc_set_id = sloc_sets.id INNER JOIN repositories ON repositories.best_code_set_id = sloc_sets.code_set_id AND repositories.id = #{repository_id}").limit(1)
  end

  def ensure_forge_and_job
    self.project.reload
    # unless self.project.forge_match
    #  self.project.save if self.project.forge_match = self.project.guess_forge
    #end
   # self.project.ensure_job
  end

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
end
