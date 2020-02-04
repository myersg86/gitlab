# frozen_string_literal: true
require 'spec_helper'

describe 'Groups > Members > List members' do
  include Select2Helper
  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:user_owner) { create(:user, name: 'John Jane') }
  let(:group) { create(:group) }

  before do
    group.add_developer(user1)

    sign_in(user1)
  end

  context 'with Group SAML identity linked for a user' do
    let(:saml_provider) { create(:saml_provider) }
    let(:group) { saml_provider.group }

    before do
      group.add_guest(user2)
      user2.identities.create!(provider: :group_saml,
                               saml_provider: saml_provider,
                               extern_uid: 'user2@example.com')
    end

    it 'shows user with SSO status badge' do
      visit group_group_members_path(group)

      member = GroupMember.find_by(user: user2, group: group)
      expect(find("#group_member_#{member.id}").find('.badge-info')).to have_content('SAML')
    end
  end

  describe 'Show warning when adding a member will incur in a charge', :js do
    let!(:gitlab_subscription) { create(:gitlab_subscription, :gold, namespace: group, seats: 1) }

    before do
      group.add_owner(user_owner)
      sign_in(user_owner)

      visit group_group_members_path(group)

      page.within '.invite-users-form' do
        select2(user2.id, from: '#user_ids', multiple: true)
        select('Developer', from: 'access_level')
      end
    end

    context 'when there are no seats left' do
      context 'when submitting the "add new member" form' do
        it 'shows a modal to block the submit going through' do
          expect(page).to have_selector('.modal#add-true-up-user-modal', visible: false)

          click_button 'Invite'

          expect(page).to have_selector('.modal#add-true-up-user-modal', visible: true)
        end
      end

      context 'when confirming the modal' do
        it 'does not contain the new user in the member list before the submit' do
          expect(page.find('.members-list')).not_to have_content(user2.name)
        end

        it 'submits the form and adds the user to the member list' do
          click_button 'Invite'

          page.within '.modal#add-true-up-user-modal' do
            click_button 'Add seat'
          end

          expect(page.find('.members-list')).to have_content(user2.name)
        end
      end

      context 'when canceling the modal' do
        before do
          click_button 'Invite'
        end

        context 'when clicking the close button' do
          it 'closes the modal without submitting the form' do
            page.find('.modal#add-true-up-user-modal .close').click

            expect(page).to have_selector('.modal#add-true-up-user-modal', visible: false)
          end
        end

        context 'when clicking the cancel button' do
          it 'closes the modal without submitting the form' do
            page.within '.modal#add-true-up-user-modal' do
              click_button 'Cancel'
            end

            expect(page).to have_selector('.modal#add-true-up-user-modal', visible: false)
          end
        end

        it 'enables the "add to group" button' do
          expect(page).to have_button('Invite', disabled: true)

          page.find('.modal#add-true-up-user-modal .close').click

          expect(page).to have_button('Invite', disabled: false)
        end
      end
    end

    context 'when there are seats left' do
      context 'when submitting the "add new member" form' do
        it 'does not show a modal to block the submit going through' do
          click_button 'Invite'

          expect(page).to have_selector('.modal#add-true-up-user-modal', visible: false)
        end
      end
    end
  end
end
