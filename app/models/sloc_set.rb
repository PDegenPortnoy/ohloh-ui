class SlocSet < ActiveRecord::Base
  has_many :analysis_sloc_sets, :dependent => :delete_all
  has_many :analyses, :through => :analysis_sloc_sets
end
