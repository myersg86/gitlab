# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        module Composable
          extend ActiveSupport::Concern

          def compose!(deps = nil)
            super(deps) do
              if @config.is_a?(Hash)
                self.compose_hash(deps)
              elsif @config.is_a?(Array)
                self.compose_array(deps)
              end
            end
          end

          def compose_hash(deps)
            @config.each do |name, config| 
              node = node_type(name, config)
              next unless node

              factory = ::Gitlab::Config::Entry::Factory.new(node)
                .value(config || {})
                .with(key: name, parent: self, description: self.class.description % name) # rubocop:disable CodeReuse/ActiveRecord
                .metadata(name: name)

              @entries[name] = factory.create!

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end

          def compose_array(deps)
            [@config].flatten.each_with_index do |value, index|
              node = self.class.node_type

              @entries[index] = ::Gitlab::Config::Entry::Factory.new(node)
                .value(value)
                .with(key: self.class.key, parent: self, description: self.class.description % value) # rubocop:disable CodeReuse/ActiveRecord
                .create!
              end

            @entries.each_value do |entry|
              entry.compose!(deps)
            end
          end

          def node_type(name=nil, config=nil)
            if self.class.node_types.size > 1
              self.class.find_type(name, config)
            else
              self.class.node_types.first
            end
          end
        end
      end
    end
  end
end