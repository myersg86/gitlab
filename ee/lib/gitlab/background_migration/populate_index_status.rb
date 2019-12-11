# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateIndexStatusForProjects

      class Namespace < ActiveRecord::Base
        def all_projects
          Project.inside_path(full_path)
        end
      end

      class Project < ActiveRecord::Base
        has_one :index_status

        scope :not_in_elasticsearch_index, -> do
          left_outer_joins(:index_status)
            .where(index_statuses: { project_id: nil })
        end

        def find_or_create_index_status!
          IndexStatus.safe_find_or_create_by!(project: self)
        end
      end

      class IndexStatus < ActiveRecord::Base
        belongs_to :project
      end

      class ApplicationSetting < ActiveRecord::Base
      end

      def perform(from_id, to_id)
        projects = Project
          .where(id: from_id..to_id)
          .not_in_elasticsearch_index

        if ApplicationSetting.first.elasticsearch_limit_indexing?
          projects = projects.where(id: ElasticsearchIndexedProject.select(:project_id))
        end

        projects.each do |project|
          project.find_or_create_index_status!
        end
      end
    end
  end
end
