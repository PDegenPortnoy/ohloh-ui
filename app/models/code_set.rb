class CodeSet < ActiveRecord::Base
  belongs_to :repository
  has_many :fyles
end