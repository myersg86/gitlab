# frozen_string_literal: true

class CreateTerraformStateVersions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:terraform_state_versions)
      with_lock_retries do
        create_table :terraform_state_versions do |t|
          t.references :terraform_state, index: false, null: false, foreign_key: { on_delete: :cascade }
          t.references :created_by_user, foreign_key: false
          t.timestamps_with_timezone null: false
          t.integer :version, null: false
          t.integer :file_store, limit: 2
          t.text :file

          t.index [:terraform_state_id, :version], unique: true, name: 'index_terraform_state_versions_on_state_id_and_version'
        end
      end
    end

    add_text_limit :terraform_state_versions, :file, 255
  end

  def down
    with_lock_retries do
      drop_table :terraform_state_versions
    end
  end
end
