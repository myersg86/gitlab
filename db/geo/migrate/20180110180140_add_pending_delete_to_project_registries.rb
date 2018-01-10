class AddPendingDeleteToProjectRegistries < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DONWTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :project_registry, :pending_delete, :boolean, default: false, allow_null: false
    add_concurrent_index :project_registry, :pending_delete
  end

  def down
    remove_column :project_registry, :pending_delete
  end
end
