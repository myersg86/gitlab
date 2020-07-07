# frozen_string_literal: true

module Gitlab
  class BulkCopy
    DELIMITER = ', '

    attr_reader :source_table, :destination_table, :source_column

    def initialize(source_table, destination_table, source_column)
      @source_table = source_table
      @destination_table = destination_table
      @source_column = source_column
    end

    def copy_between(start_id, stop_id)
      connection.execute(<<~SQL)
        INSERT INTO #{destination_table} (#{column_listing})
        SELECT #{column_listing}
        FROM #{source_table}
        WHERE #{source_column} BETWEEN #{start_id} AND #{stop_id}
        FOR UPDATE
        ON CONFLICT (#{conflict_targets}) DO NOTHING
      SQL
    end

    private

    def connection
      @connection ||= ActiveRecord::Base.connection
    end

    def column_listing
      @column_listing ||= connection.columns(source_table).map(&:name).join(DELIMITER)
    end

    def conflict_targets
      connection.primary_key(destination_table).join(DELIMITER)
    end
  end
end
