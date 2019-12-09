# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateIndexStatus < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  MIGRATION = 'PopulateIndexStatus'

  disable_ddl_transaction!

  class ElasticsearchIndexedNamespace < ActiveRecord::Base
    include EachBatch

    self.primary_key = :namespace_id
  end

  class ElasticsearchIndexedProject < ActiveRecord::Base
    include EachBatch

    self.primary_key = :project_id
  end

  def up
    return unless Gitlab.ee?

    say "Scheduling `#{MIGRATION}` jobs for indexed namespaces"

    ElasticsearchIndexedNamespace.each do |namespace|
      neach_batch(column: :created_at) do |indexed_projects|
      Gitlab::BackgroundMigration::PopulateIndexStatus.perform_async(indexed_projects.pluck(:project_id))
    end

    say "Scheduling `#{MIGRATION}` jobs for indexed projects"

    ElasticsearchIndexedProject.each_batch(column: :created_at) do |indexed_projects|
      Gitlab::BackgroundMigration::PopulateIndexStatus.perform_async(indexed_projects.pluck(:project_id))
    end
  end

  def down
    # no-op
  end
end
