# frozen_string_literal: true

module Gitlab
  module Database
    module BulkInsertSupport
      extend ActiveSupport::Concern

      AlreadyActiveError = Class.new(StandardError)

      class BulkInsertState
        attr_reader :captures, :callbacks

        def initialize
          @captures = []
          @callbacks = nil
        end

        def add_capture(capture)
          @captures << capture
        end

        def inject_last_values!(values)
          @captures.last[:values] = values
        end

        def store_callbacks(callbacks)
          @callbacks = callbacks
        end
      end

      class_methods do
        def save_all!(*items)
          raise AlreadyActiveError.new("Cannot nest bulk inserts") if _gl_bulk_inserts_requested?

          self.transaction do
            p "BEGIN TRANSACTION"

            _gl_set_bulk_insert_state
            _gl_delay_callbacks

            items.each do |item|
              raise "Wrong instance type %s, expected T < %s" % [item.class, self] unless item.is_a? self

              item.save!
            end

            _gl_bulk_insert
            _gl_restore_callbacks
            _gl_replay_callbacks

            p "END TRANSACTION"
          end
        ensure
          _gl_release_bulk_insert_state
        end

        def _gl_bulk_inserts_requested?
          !!_gl_bulk_insert_state
        end

        def _gl_capture_record(record)
          _gl_bulk_insert_state.add_capture(record)
        end

        # Overrides ActiveRecord::Persistence::ClassMethods._insert_record
        def _insert_record(values)
          if _gl_bulk_inserts_requested?
            p "!! delaying row #{values} for bulk insert"
            _gl_bulk_insert_state.inject_last_values!(values)
          else
            super
          end
        end

        private

        def _gl_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state]&.fetch(self.class, nil)
        end

        def _gl_set_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state] = {
            self.class => BulkInsertState.new
          }
        end

        def _gl_release_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state] = nil
        end

        def _gl_delay_callbacks
          # make backup of original callback chain
          _gl_bulk_insert_state.store_callbacks(_save_callbacks.deep_dup)

          # remove after_save callbacks, so that they won't be invoked
          _save_callbacks.send(:chain).reject! { |c| c.kind == :after }
        end

        def _gl_restore_callbacks
          stored_callbacks = _gl_bulk_insert_state.callbacks

          _save_callbacks = stored_callbacks
          __callbacks[:save] = stored_callbacks
        end

        def _gl_replay_callbacks
          p "REPLAYING after_save"
          _gl_bulk_insert_state.captures.each do |capture|
            target = capture[:target]
            _gl_run_save_callback(target, :after)
          end
        end

        # Because `run_callbacks` will run _all_ callbacks for e.g. `save`,
        # we need to filter out anything that is not of the given `kind` first.
        def _gl_run_save_callback(target, kind)
          current_callbacks = _save_callbacks.deep_dup

          requested_chain = _save_callbacks.send(:chain)
          requested_chain.reject! { |c| c.kind != kind }

          target.run_callbacks :save

          _save_callbacks = current_callbacks
          __callbacks[:save] = current_callbacks
        end

        def _gl_bulk_insert
          p "BULK INSERT"

          # obtains all captured model instances & row values
          captures = _gl_bulk_insert_state.captures

          values = captures.map { |c| c[:values] }

          ids = Gitlab::Database.bulk_insert(table_name, values, return_ids: true)
          p "--> row IDs: #{ids.inspect}"

          # inject row IDs back into model instances
          if ids && ids.any?
            captures.zip(ids).each { |c, id| c[:target].id = id }
          end
        end
      end

      private

      # Overrides ActiveRecord::*._create_record
      def _create_record(*)
        if self.class._gl_bulk_inserts_requested?
          # We need to hold on to the current instance, so that we can
          # inject IDs into them later on.
          # The row `values` will be injected later in `_insert_record`/
          self.class._gl_capture_record({
            target: self,
            values: nil
          })
        end

        super
      end
    end
  end
end
