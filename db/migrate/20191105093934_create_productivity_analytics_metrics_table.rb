# frozen_string_literal: true

class CreateProductivityAnalyticsMetricsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :analytics_productivity_analytics_metrics do |t|
      t.bigint :merge_request_id, null: false
      t.datetime :merged_at, null: false
      t.datetime :opened_at, null: false # as an alternative we can use delegation to #merge_request
      t.integer :pipelines_count, null: false, default: 0
      t.integer :failed_pipelines_count, null: false, default: 0
      t.timestamps
    end

    add_index :analytics_productivity_analytics_metrics, :merge_request_id, unique: true, name: 'index_pa_metrics_on_merge_request_id'
    add_index :analytics_productivity_analytics_metrics, :merged_at, name: 'index_pa_metrics_on_merged_at'
  end
end
