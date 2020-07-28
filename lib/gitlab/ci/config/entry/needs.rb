# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of needs dependencies.
        #
        class Needs < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Composable
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validate do
              unless config.is_a?(Hash) || config.is_a?(Array)
                errors.add(:config, 'can only be a Hash or an Array')
              end

              if config.is_a?(Hash) && config.empty?
                errors.add(:config, 'can not be an empty Hash')
              end
            end

            validate on: :composed do
              extra_keys = value.keys - opt(:allowed_needs)
              if extra_keys.any?
                errors.add(:config, "uses invalid types: #{extra_keys.join(', ')}")
              end
            end
          end

          def self.description
            "need definition."
          end

          def self.key
            "need"
          end

          def self.node_type
            Entry::Need
          end

          def value
            values = @entries.values.select(&:type)
            values.group_by(&:type).transform_values do |values|
              values.map(&:value)
            end
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Needs.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Needs')
