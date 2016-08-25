class Release < ActiveRecord::Base
  belongs_to :project_security_set
  has_many :releases_vulnerabilities
  has_many :vulnerabilities, through: :releases_vulnerabilities
end
