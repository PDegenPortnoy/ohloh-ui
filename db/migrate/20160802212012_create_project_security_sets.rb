class CreateProjectSecuritySets < ActiveRecord::Migration
  def change
    create_table :project_security_sets do |t|
      t.string :project_id, null: false
      t.string :uuid, null: false
      t.timestamps null: false
    end
  end
end
