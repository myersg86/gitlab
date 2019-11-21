# frozen_string_literal: true

module EE
  module ProjectPresenter
    extend ::Gitlab::Utils::Override

    include NpmHelper

    override :statistics_buttons
    def statistics_buttons(show_auto_devops_callout:, show_add_npmrc: false)
      super(show_auto_devops_callout: show_auto_devops_callout) + extra_statistics_buttons(show_add_npmrc: show_add_npmrc)
    end

    def extra_statistics_buttons(show_add_npmrc: false)
      buttons = []

      if can?(current_user, :read_project_security_dashboard, project)
        buttons << security_dashboard_data
      end

      buttons << npmrc_anchor_data if show_add_npmrc

      buttons.compact
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

      if current_user && can_current_user_push_to_default_branch?
        OpenStruct.new(is_link: false,
          label: statistic_icon + _('Add .npmrc'),
          link: add_npmrc_path)
      end
    end

    private

    def security_dashboard_data
      OpenStruct.new(is_link: false,
                     label: statistic_icon('lock') + _('Security Dashboard'),
                     link: project_security_dashboard_path(project),
                     class_modifier: 'default')
    end
  end
end
