# frozen_string_literal: true

module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap do |group|
          if group&.persisted?
            log_audit_event
            create_predefined_push_rule
          end
        end
      end

      private

      override :after_build_hook
      def after_build_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
        end
      end

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :create
        ).for_group.security_event
      end

      def create_predefined_push_rule
        return unless group.feature_available?(:push_rules)

        push_rule = group.predefined_push_rule
        return unless push_rule

        attributes = push_rule.attributes.symbolize_keys.except(:project_id, :is_sample, :id)
        group.create_group_push_rule(attributes)
      end
    end
  end
end
