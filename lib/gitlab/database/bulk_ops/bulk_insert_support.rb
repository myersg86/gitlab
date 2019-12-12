# frozen_string_literal: true

module Gitlab
  module Database
    module BulkInsertSupport
      extend ActiveSupport::Concern

      AlreadyActiveError = Class.new(StandardError)

      class BulkInsertState
        attr_reader :captures

        def self.set!(clazz, instance = BulkInsertState.new)
          p "request bulk inserts for #{clazz}"
          Thread.current[:_gl_bulk_insert_state] ||= {}
          Thread.current[:_gl_bulk_insert_state][clazz] = instance
        end

        def self.unset!(clazz)
          set!(clazz, nil)
        end

        def self.get(clazz)
          Thread.current[:_gl_bulk_insert_state]&.fetch(clazz, nil)
        end

        def initialize
          @captures = []
        end

        def add_capture!(capture)
          @captures << capture
        end

        def inject_last_values!(values)
          @captures.last[:set_values].call(values)
        end
      end

      class_methods do
        def with_bulk_inserts(&block)
          raise AlreadyActiveError.new("Cannot nest bulk inserts") if BulkInsertState.get(self)

          # TODO: this should probably be bound to a transaction somehow
          BulkInsertState.set!(self)

          self.transaction do
            yield
            _gl_bulk_insert!
          end

        ensure
          BulkInsertState.unset!(self)
        end

        def _gl_bulk_inserts_requested?
          p "requested for #{self} = #{!!BulkInsertState.get(self)}"
          !!BulkInsertState.get(self)
        end

        # pre-conditions: `BulkInsertState` != nil && BulkInsertState.get.captures != nil
        def _gl_bulk_insert!
          p "// flushing delayed inserts"

          captures = BulkInsertState.get(self).captures

          values = captures.map { |c| c[:values] }

          ids = Gitlab::Database.bulk_insert(table_name, values, return_ids: true)
          p "inserted IDs: #{ids.inspect}"

          if ids && ids.any?
            captures.zip(ids).each { |c, id| c[:set_id].call(id) }
          end
          # TODO: assert ids.size == values.size
        end

        # Overrides ActiveRecord::Persistence::ClassMethods._insert_record
        def _insert_record(values)
          if _gl_bulk_inserts_requested?
            p "!! delaying row #{values} for bulk insert"
            BulkInsertState.get(self).inject_last_values!(values)
          else
            super
          end
        end
      end

      private

      # Overrides ActiveRecord::*._create_record
      def _create_record(*)
        if self.class._gl_bulk_inserts_requested?
          record_capture = {
            set_id: ->(id) { self.id ||= id },
            set_values: -> (values) { record_capture[:values] = values }
          }
          BulkInsertState.get(self.class).add_capture!(record_capture)
        end

        super
      end
    end
  end
end
