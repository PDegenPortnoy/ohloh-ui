class Organization < ActiveRecord::Base
  has_one :permission, as: :target
  has_many :projects, -> { where { deleted.not_eq true } }
  has_many :accounts
  has_many :manages, -> { where(deleted_at: nil, deleted_by: nil) }, as: 'target'
  has_many :managers, through: :manages, source: :account
  belongs_to :logo

  scope :active, -> { where { deleted.not_eq true } }
  scope :from_param, ->(param) { where(url_name: param) }

  def to_param
    url_name
  end

  def active_managers
    Manage.organizations.for_target(self).active.to_a.map(&:account)
  end
end
