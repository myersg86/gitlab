import $ from 'jquery';
import createFlash from '~/flash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import Members from '~/members';

export default class MembersEE extends Members {
  hasConfirmedAddingMember = false;

  addListeners() {
    super.addListeners();

    $('.js-ldap-permissions')
      .off('click')
      .on('click', this.showLDAPPermissionsWarning.bind(this));
    $('.js-ldap-override')
      .off('click')
      .on('click', this.toggleMemberAccessToggle.bind(this));
    const $addMemberForm = $('form.invite-users-form');
    $addMemberForm.on('submit', this.showTrueUpModal.bind(this));
    $('#add-true-up-user-modal')
      .find('.confirm-adding-member-to-group')
      .click(this.continueFormSubmitting.bind(this));
  }

  dropdownClicked(options) {
    options.e.preventDefault();

    const $link = options.$el;

    if (!$link.data('revert')) {
      this.formSubmit(null, $link);
    } else {
      const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($link);

      $toggle.disable();
      $dateInput.disable();

      MembersEE.overrideLdap($memberListItem, $link.data('endpoint'), false).catch(() => {
        $toggle.enable();
        $dateInput.enable();
      });
    }
  }

  dropdownToggleLabel(selected, $el, $btn) {
    if ($el.data('revert')) {
      return $btn.text();
    }

    return super.dropdownToggleLabel(selected, $el, $btn);
  }

  dropdownIsSelectable(selected, $el) {
    if ($el.data('revert')) {
      return false;
    }

    return super.dropdownIsSelectable(selected, $el);
  }

  showLDAPPermissionsWarning(e) {
    const $btn = $(e.currentTarget);
    const { $memberListItem } = this.getMemberListItems($btn);
    const $ldapPermissionsElement = $memberListItem.next();

    $ldapPermissionsElement.toggle();
  }

  toggleMemberAccessToggle(e) {
    const $btn = $(e.currentTarget);
    const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($btn);

    $btn.disable();
    MembersEE.overrideLdap($memberListItem, $btn.data('endpoint'), true)
      .then(() => {
        this.showLDAPPermissionsWarning(e);

        $toggle.enable();
        $dateInput.enable();
      })
      .catch(xhr => {
        $btn.enable();

        if (xhr.status === 403) {
          createFlash(
            __(
              'You do not have the correct permissions to override the settings from the LDAP group sync.',
            ),
          );
        } else {
          createFlash(__('An error occurred while saving LDAP override status. Please try again.'));
        }
      });
  }

  showTrueUpModal(e) {
    const $addMemberForm = $('form.invite-users-form');
    const membersBeingAdded = $('#user_ids')
      .val()
      .split(',').length;
    const {
      isFreePlan,
      maxSeatsUsed,
      seatsInUse,
      // seatsOwed,
      subscriptionSeats,
    } = $addMemberForm.data();

    const baseUserCount = subscriptionSeats < maxSeatsUsed ? maxSeatsUsed : subscriptionSeats;
    const overUsers = Math.abs(baseUserCount - (seatsInUse + membersBeingAdded));

    // Show the modal if:
    // - the group is not on free plan
    // - this event isn't triggered by submit programmatically
    // - the max seats is about to increase
    if (!isFreePlan && !this.hasConfirmedAddingMember && overUsers > 0) {
      e.preventDefault();
      $('#add-true-up-user-modal')
        .modal()
        .on('hide.bs.modal', () => {
          if (!this.hasConfirmedAddingMember) {
            // enable "Add to group" button
            $addMemberForm
              .find('input[type="submit"]')
              .removeClass('disabled')
              .removeAttr('disabled');
          }
        });
    }
  }

  continueFormSubmitting() {
    this.hasConfirmedAddingMember = true;
    const $addMemberForm = $('form.invite-users-form');
    $addMemberForm.submit();
  }

  static overrideLdap($memberListitem, endpoint, override) {
    return axios
      .patch(endpoint, {
        group_member: {
          override,
        },
      })
      .then(() => {
        $memberListitem.toggleClass('is-overridden', override);
      });
  }
}
