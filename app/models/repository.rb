class Repository < ActiveRecord::Base
  has_many :enlistments
  has_many :projects, through: :enlistments
  belongs_to :best_code_set, :foreign_key => 'best_code_set_id', :class_name => 'CodeSet'
end
