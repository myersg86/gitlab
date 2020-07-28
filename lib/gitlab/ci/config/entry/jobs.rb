# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of jobs.
        #
        class Jobs < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Composable
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Hash

            validate do
              unless has_valid_jobs?
                errors.add(:config, 'should contain valid jobs')
              end

              unless has_visible_job?
                errors.add(:config, 'should contain at least one visible job')
              end
            end

            def has_valid_jobs?
              config.all? do |name, value|
                Jobs.find_type(name, value)
              end
            end

            def has_visible_job?
              config.any? do |name, value|
                Jobs.find_type(name, value)&.visible?
              end
            end
          end

          def self.node_types
            [Entry::Hidden, Entry::Job, Entry::Bridge].freeze
          end

          def self.all_types
            Jobs.node_types
          end

          def  self.description
            "%s job definition."
          end

          def self.find_type(name, config)
            Jobs.node_types.find do |type|
              type.matching?(name, config)
            end
          end
        end
      end
    end
  end
end
