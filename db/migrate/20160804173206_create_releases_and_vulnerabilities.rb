class CreateReleasesAndVulnerabilities < ActiveRecord::Migration
  def change
    create_table :releases_vulnerabilities do |t|
      t.integer  :release_id
      t.integer  :vulnerability_id
    end
   
  end
end
