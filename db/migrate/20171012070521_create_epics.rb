# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :epics do |t|
      t.string :title, null: false
      t.text :description
      t.integer :author_id, null: false
      t.integer :group_id, null: false
      t.string :state, null: false
      t.date :start_date
      t.date :end_date

      t.timestamps_with_timezone
    end

    add_concurrent_foreign_key :epics, :namespaces, column: :group_id
    add_concurrent_foreign_key :epics, :users, column: :author_id
  end

  def down
    remove_foreign_key :epics, column: :group_id
    remove_foreign_key :epics, column: :author_id

    drop_table :epics
  end
end
