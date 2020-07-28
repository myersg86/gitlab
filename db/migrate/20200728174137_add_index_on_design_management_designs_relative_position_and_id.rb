# frozen_string_literal: true

class AddIndexOnDesignManagementDesignsRelativePositionAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_designs, [:relative_position, :id]
  end

  def down
    remove_concurrent_index :design_management_designs, [:relative_position, :id]
  end
end
