# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateIndexStatus

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
        #self.primary_key = :namespace_id
      end

      def perform
        ElasticsearchIndexedNamespace.find_each do |namespace|
          namespace.all_projects.not_in_elasticsearch_index.find_each do |project|
            project.find_or_create_index_status!
          end
        end

        ElasticsearchIndexedProject.find_each do |project|
          project.find_or_create_index_status!
        end
      end
    end
  end
end
