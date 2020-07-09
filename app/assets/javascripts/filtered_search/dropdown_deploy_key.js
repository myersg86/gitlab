import DropdownAjaxFilter from './dropdown_ajax_filter';

export default class DropdownDeployKey extends DropdownAjaxFilter {
  constructor(options = {}) {
    super({
      ...options,
      endpoint: '/-/autocomplete/deploy_keys_with_owners.json',
      symbol: '@',
    });
  }

  ajaxFilterConfig() {
    return {
      ...super.ajaxFilterConfig(),
      params: {
        active: true,
        group_id: this.getGroupId(),
        project_id: this.getProjectId(),
        current_user: true,
        ...this.projectOrGroupId(),
      },
    };
  }

  getGroupId() {
    return this.input.getAttribute('data-group-id');
  }

  getProjectId() {
    return this.input.getAttribute('data-project-id');
  }

  projectOrGroupId() {
    const projectId = this.getProjectId();
    const groupId = this.getGroupId();
    if (groupId) {
      return {
        group_id: groupId,
      };
    }
    return {
      project_id: projectId,
    };
  }
}
