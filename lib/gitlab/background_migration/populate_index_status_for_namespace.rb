# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateIndexStatusForNamespace

      class Namespace < ActiveRecord::Base
        def all_projects
          Project.inside_path(full_path)
        end
      end

      class Project < ActiveRecord::Base
        has_one :index_status

        def find_or_create_index_status!
          IndexStatus.safe_find_or_create_by!(project: self)
        end
      end

      class IndexStatus < ActiveRecord::Base
        belongs_to :project
      end

      def perform(namespace_id)
        namespace = Namespace.find(namespace_id)

        namespace.all_projects.each_batch do |projects|
          projects.each do |project|
            project.find_or_create_index_status!
          end
        end
      end
    end
  end
end
