# frozen_string_literal: true

module EE
  module IdeController
    extend ActiveSupport::Concern

    prepended do
      before_action do
        if License.feature_available?(:ide_schema_config)
          push_frontend_feature_flag(:ide_schema_config, default_enabled: true)
        end
      end
    end
  end
end
