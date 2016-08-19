class ProjectSecuritySet < ActiveRecord::Base
	has_many :releases
	belongs_to :project
	#36913fa0-e807-4367-8595-4f13b5a5ba66
	def create
		#create release objects, usually happens when there is no security data available for the current project
		return if project_id?	
	end

	def update
		#update release objects, happens when there is a change in the etag of the project
	end

	def delete
		#delete release objects, happens when there have been fixes in the releases/ when the KB API no longer has the releases which were saved earlier
	end
end
