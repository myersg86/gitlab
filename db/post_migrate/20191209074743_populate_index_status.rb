# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateIndexStatus < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  DELAY_INTERVAL = 8.minutes.to_i

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    def all_projects
      Project.inside_path(full_path)
    end
  end

  class Project < ActiveRecord::Base
    scope :not_in_elasticsearch_index, -> do
      left_outer_joins(:index_status)
        .where(index_statuses: { project_id: nil })
    end

    scope :inside_path, ->(path) do
      # We need routes alias rs for JOIN so it does not conflict with
      # includes(:route) which we use in ProjectsFinder.
      joins("INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'")
        .where('rs.path LIKE ?', "#{sanitize_sql_like(path)}/%")
    end

    def find_or_create_index_status!
      IndexStatus.safe_find_or_create_by!(project: self)
    end
  end

  class IndexStatus < ActiveRecord::Base
    belongs_to :project
  end

  class ElasticsearchIndexedNamespace < ActiveRecord::Base
    #self.primary_key = :namespace_id
  end

  class ElasticsearchIndexedProject < ActiveRecord::Base
    #self.primary_key = :project_id
  end

  class ApplicationSetting < ActiveRecord::Base
  end

  def up
    return unless Gitlab.ee?
    return unless ApplicationSetting.first.elasticsearch_indexing?

    projects = Project.all

    if ApplicationSetting.first.elasticsearch_limit_indexing?
      projects = projects.where(id: ElasticsearchIndexedProject.select(:project_id))

      namespace_ids = ElasticsearchIndexedNamespace.pluck(:namespace_id)

      namespace_ids.each do |namespace_id|
        Gitlab::BackgroundMigration::PopulateIndexStatusForNamespace.perform_async(namespace_id)
      end

      queue_background_migration_jobs_by_range_at_intervals(
        namespaces,
        'Gitlab::BackgroundMigration::PopulateIndexStatusForNamespace',
        DELAY_INTERVAL,
        batch_size: BATCH_SIZE
      )
    end

    queue_background_migration_jobs_by_range_at_intervals(
      projects,
      'Gitlab::BackgroundMigration::PopulateIndexStatusForProjects',
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )

  end

  def down
    # no-op
  end
end
