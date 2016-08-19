class CreateVulnerabilities < ActiveRecord::Migration
  def change
    create_table :vulnerabilities do |t|
      t.string :cve_id, null: false
      t.datetime :published_on
      t.datetime :generated_on
      t.integer :severity
      t.timestamps null: false
    end
  end
end
