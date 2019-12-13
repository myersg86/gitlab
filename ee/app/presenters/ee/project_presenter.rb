# frozen_string_literal: true

module EE
  module ProjectPresenter
    extend ::Gitlab::Utils::Override

    include NpmHelper

    override :statistics_buttons
    def statistics_buttons(show_auto_devops_callout:)
      super + extra_statistics_buttons
    end

    def extra_statistics_buttons
      [
        security_dashboard_data,
        npmrc_anchor_data
      ].compact
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(project.approver_groups, current_user)
    end

    def npmrc_path
      filename_path(:npmrc)
    end

    def add_npmrc_path
      add_special_file_path(file_name: '.npmrc', content: generate_npmrc_template_content)
    end

    def npmrc_anchor_data
      if repository.npmrc.present?
        return OpenStruct.new(is_link: false,
          label: statistic_icon('doc-text') + _('.npmrc'),
          link: npmrc_path,
          class_modifier: 'default')
      end

      if current_user && can_current_user_push_to_default_branch? && repository.file_on_head(:package_json).present?
        OpenStruct.new(is_link: false,
          label: statistic_icon + _('Add .npmrc'),
          link: add_npmrc_path)
      end
    end

    def security_dashboard_data
      if can?(current_user, :read_project_security_dashboard, project)
        OpenStruct.new(is_link: false,
                      label: statistic_icon('lock') + _('Security Dashboard'),
                      link: project_security_dashboard_path(project),
                      class_modifier: 'default')
      end
    end
  end
end
