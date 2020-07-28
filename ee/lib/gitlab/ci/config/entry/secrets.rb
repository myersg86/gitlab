# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a secrets definition.
        #
        class Secrets < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Ci::Config::Entry::Composable

          validations do
            validates :config, type: Hash
          end

          def self.node_types
            [Entry::Secret]
          end

          def self.description
            "%s secret definition"
          end
        end
      end
    end
  end
end