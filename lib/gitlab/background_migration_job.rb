# frozen_string_literal: true

module Gitlab
  class BackgroundMigrationJob < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    include EachBatch

    self.table_name = :background_migration_jobs

    scope :for_batch, -> (start_id, end_id) { where(start_id: start_id, end_id: end_id) }
    scope :for_migration, -> (name, arguments: []) do
      relation = where(name: name)
      arguments.each_with_index.reduce(relation) do |relation, (arg, i)|
        relation.where("arguments->#{i} = ?", arg.to_json) # rubocop:disable GitlabSecurity/SqlInjection
      end
    end

    enum status: {
      pending: 0,
      completed: 1
    }

    def self.complete_all(name, start_id, end_id, arguments: [])
      self.pending.for_migration(name, arguments: arguments).for_batch(start_id, end_id)
        .update_all("status = #{statuses[:completed]}, updated_at = NOW()")
    end
  end
end
