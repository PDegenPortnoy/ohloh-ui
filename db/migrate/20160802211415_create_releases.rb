class CreateReleases < ActiveRecord::Migration
  def change
    create_table :releases do |t|
      t.string :release_id, null: false
      t.datetime :released_on
      t.string :version_name
      t.belongs_to :project_security_set,  index: true
      t.timestamps null: false
    end
  end
end
