# frozen_string_literal: true

module Gitlab
  module Database
    module BulkInsertSupport
      extend ActiveSupport::Concern

      NestedCallError = Class.new(StandardError)
      TargetTypeError = Class.new(StandardError)

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
          @callbacks = callbacks.deep_dup
        end

        def callbacks_for(name)
          @callbacks[name].deep_dup
        end
      end

      class_methods do
        def save_all!(*items)
          raise NestedCallError.new("Cannot nest bulk inserts") if _gl_bulk_inserts_requested?

          self.transaction do
            _gl_set_bulk_insert_state
            _gl_delay_callbacks

            items.flatten.each do |item|
              unless item.is_a?(self)
                raise TargetTypeError.new("Wrong instance type %s, expected T <= %s" % [item.class, self])
              end

              item.save!
            end

            _gl_bulk_insert
            _gl_restore_callbacks
            _gl_replay_callbacks
          end
        ensure
          # might be called redundantly, but if we terminated abnormally anywhere
          # due to an exception, we must restore the class' callback structure
          _gl_restore_callbacks
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
            _gl_bulk_insert_state.inject_last_values!(values)
          else
            super
          end
        end

        private

        def _gl_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state]&.fetch(self, nil)
        end

        def _gl_set_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state] = {
            self => BulkInsertState.new
          }
        end

        def _gl_release_bulk_insert_state
          Thread.current[:_gl_bulk_insert_state] = nil
        end

        def _gl_delay_callbacks
          # make backup of original callback chain
          _gl_bulk_insert_state.store_callbacks(__callbacks)

          # remove after_save callbacks, so that they won't be invoked
          _save_callbacks.__send__(:chain).reject! { |c| c.kind == :after }
        end

        def _gl_restore_callbacks
          return unless _gl_bulk_insert_state

          stored_callbacks = _gl_bulk_insert_state.callbacks

          if stored_callbacks&.any?
            _save_callbacks = stored_callbacks[:save]
            __callbacks[:save] = stored_callbacks[:save]
          end
        end

        def _gl_replay_callbacks
          _gl_bulk_insert_state.captures.each do |capture|
            target = capture[:target]
            _gl_run_save_callback(target, :after)
          end
        end

        # Because `run_callbacks` will run _all_ callbacks for e.g. `save`,
        # we need to filter out anything that is not of the given `kind` first.
        #
        # TODO: this is currently hacky and inefficient, since it involves a lot
        # of copying of callback structures. This only needs to happen once per
        # replay, not for every item.
        def _gl_run_save_callback(target, kind)
          # obtain a copy of the stored/original save callbacks
          requested_callbacks = _gl_bulk_insert_state.callbacks_for(:save)

          # retain only callback hooks of the requested kind
          requested_callbacks.__send__(:chain).reject! { |c| c.kind != kind }
          _save_callbacks = requested_callbacks
          __callbacks[:save] = requested_callbacks

          target.run_callbacks :save

          # restore callbacks to previous state
          _gl_restore_callbacks
        end

        def _gl_bulk_insert
          # obtains all captured model instances & row values
          captures = _gl_bulk_insert_state.captures

          values = captures.map { |c| c[:values] }

          ids = Gitlab::Database.bulk_insert(table_name, values, return_ids: true)

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
