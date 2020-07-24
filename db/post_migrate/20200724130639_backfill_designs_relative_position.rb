# frozen_string_literal: true

class BackfillDesignsRelativePosition < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  BATCH_SIZE = 100
  MIGRATION = 'BackfillDesignsRelativePosition'

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'

    has_many :designs
  end

  class Design < ActiveRecord::Base
    self.table_name = 'design_management_designs'
  end

  def up
    issues_with_designs = Issue.joins(:designs).distinct

    queue_background_migration_jobs_by_range_at_intervals(
      issues_with_designs,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
  end
end
