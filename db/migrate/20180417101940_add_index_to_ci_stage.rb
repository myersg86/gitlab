class AddIndexToCiStage < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_stages, :index, :integer
  end
end
