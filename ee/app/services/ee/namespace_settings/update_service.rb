# frozen_string_literal: true

module EE
  # This class is responsible for updating the namespace settings of a specific group.

  module NamespaceSettings
    class UpdateService
      include ::Gitlab::Allowable

      def initialize(current_user, group, settings)
        @current_user = current_user
        @group = group
        @settings_params = settings
      end

      def execute
        if settings_params.key?(:prevent_forking_outside_group)
          unless can_update_prevent_forking?
            group.errors.add(:prevent_forking_outside_group, s_('GroupSettings|Prevent forking setting was not saved'))
            return
          end
        end

        group.namespace_settings ? group.namespace_settings.attributes = settings_params : group.build_namespace_settings(settings_params)
      end

      private

      attr_reader :current_user, :group, :settings_params

      def can_update_prevent_forking?
        can?(current_user, :change_prevent_group_forking, group)
      end
    end
  end
end
