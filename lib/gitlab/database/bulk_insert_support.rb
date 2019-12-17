# frozen_string_literal: true

module Gitlab
  module Database
    module BulkInsertSupport
      extend ActiveSupport::Concern

      NestedCallError = Class.new(StandardError)
      TargetTypeError = Class.new(StandardError)

      DELAYED_CALLBACKS = [:save, :create].freeze

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

      # We currently reach into internal APIs, which requires __send__
      # rubocop: disable GitlabSecurity/PublicSend
      class_methods do
        def save_all!(*items)
          raise NestedCallError.new("Cannot nest bulk inserts") if _gl_bulk_inserts_requested?

          # Until we find a better way to delay AR callbacks than rewriting them,
          # we need to protect the entire transaction from other threads. Since
          # callbacks are class-level instances, they might otherwise interfere
          # with each other.
          # This essentially means that bulk inserts are entirely sequential even
          # in multi-threaded setups.
          @_gl_bulk_insert_lock ||= Mutex.new
          @_gl_bulk_insert_lock.synchronize do
            self.transaction do
              _gl_set_bulk_insert_state
              _gl_delay_after_callbacks

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

        def _gl_delay_after_callbacks
          # make backup of original callback chain
          _gl_bulk_insert_state.store_callbacks(__callbacks)

          # remove after_* callbacks, so that they won't be invoked
          DELAYED_CALLBACKS.each do |cb|
            _gl_suppress_callbacks(_gl_get_callback_chain(cb)) { |cb| cb.kind == :after }
          end
        end

        def _gl_restore_callbacks
          return unless _gl_bulk_insert_state

          stored_callbacks = _gl_bulk_insert_state.callbacks

          if stored_callbacks&.any?
            DELAYED_CALLBACKS.each do |cb|
              _gl_set_callback_chain(stored_callbacks[cb], cb)
            end
          end
        end

        def _gl_replay_callbacks
          _gl_bulk_insert_state.captures.each do |capture|
            target = capture[:target]
            _gl_run_callback(target, :after, :create)
            _gl_run_callback(target, :after, :save)
          end
        end

        # Because `run_callbacks` will run _all_ callbacks for e.g. `save`,
        # we need to filter out anything that is not of the given `kind` first.
        #
        # TODO: this is currently hacky and inefficient, since it involves a lot
        # of copying of callback structures. This only needs to happen once per
        # replay, not for every item.
        def _gl_run_callback(target, kind, name)
          # obtain a copy of the stored/original save callbacks
          requested_callbacks = _gl_bulk_insert_state.callbacks_for(name)

          # retain only callback hooks of the requested kind
          _gl_suppress_callbacks(requested_callbacks) { |cb| cb.kind != kind }
          _gl_set_callback_chain(requested_callbacks, name)

          target.run_callbacks name

          # restore callbacks to previous state
          _gl_restore_callbacks
        end

        def _gl_get_callback_chain(name)
          __send__("_#{name}_callbacks")
        end

        # `callback_chain`: ActiveSupport::Callbacks::CallbackChain
        # `name`: :save, :create, ...
        def _gl_set_callback_chain(callback_chain, name)
          __send__("_#{name}_callbacks=", callback_chain)
          __callbacks[name] = callback_chain
        end

        # `callback_chain`: ActiveSupport::Callbacks::CallbackChain
        # `kind`: :before, :after, ...
        def _gl_suppress_callbacks(callback_chain, &block)
          callback_chain.__send__(:chain).reject!(&block)
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
