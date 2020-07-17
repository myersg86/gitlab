import $ from 'jquery';
import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';
import AccessDropdown from 'ee/projects/settings/access_dropdown';
import CreateItemDropdown from '../create_item_dropdown';
import AccessorUtilities from '../lib/utils/accessor';
import { ACCESS_LEVELS } from './constants';
import { __ } from '~/locale';

export default class ProtectedBranchCreate {
  constructor() {
    this.deployKeysOnProtectedBranchesEnabled = gon.features.deployKeysOnProtectedBranches;

    this.$form = $('.js-new-protected-branch');
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.currentProjectUserDefaults = {};
    this.buildDropdowns();
  }

  buildDropdowns() {
    const $allowedToMergeDropdown = this.$form.find('.js-allowed-to-merge');
    const $allowedToPushDropdown = this.$form.find('.js-allowed-to-push');
    const $protectedBranchDropdown = this.$form.find('.js-protected-branch-select');

    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Merge dropdown
    this.protectedBranchMergeAccessDropdown = new ProtectedBranchAccessDropdown({
      $dropdown: $allowedToMergeDropdown,
      data: gon.merge_access_levels,
      onSelect: this.onSelectCallback,
    });

    // Allowed to Push dropdown
    if (this.deployKeysOnProtectedBranchesEnabled) {
      this[`${ACCESS_LEVELS.PUSH}_dropdown`] = new AccessDropdown({
        $dropdown: $allowedToPushDropdown,
        accessLevelsData: gon.push_access_levels,
        onSelect: this.onSelectCallback,
        accessLevel: 'push_access_levels',
        hasLicense: false,
      });
    } else {
      this.protectedBranchPushAccessDropdown = new ProtectedBranchAccessDropdown({
        $dropdown: $allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelectCallback,
      });
    }

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: $protectedBranchDropdown,
      defaultToggleLabel: __('Protected Branch'),
      fieldName: 'protected_branch[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedBranchCreate.getProtectedBranches,
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$form.find('input[name="protected_branch[name]"]');

    const $allowedToMergeInput = this.$form.find(
      'input[name="protected_branch[merge_access_levels_attributes][0][access_level]"]',
    );
    const $allowedToPushInput = this.getPushLevelValues();

    const completedForm = !(
      $branchInput.val() &&
      $allowedToMergeInput.length &&
      $allowedToPushInput.length
    );

    this.$form.find('input[type="submit"]').prop('disabled', completedForm);
  }

  static getProtectedBranches(term, callback) {
    callback(gon.open_branches);
  }

  getPushLevelValues() {
    let values;

    if (this.deployKeysOnProtectedBranchesEnabled) {
      values = this[`${ACCESS_LEVELS.PUSH}_dropdown`].getSelectedItems();
    } else {
      values = this.$form.find(
        'input[name="protected_branch[push_access_levels_attributes][0][access_level]"]',
      );
    }

    return values;
  }
}
