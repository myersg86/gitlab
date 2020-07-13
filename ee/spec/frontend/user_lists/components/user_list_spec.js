import Vue from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { uniq } from 'lodash';
import { GlAlert, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import { userList } from '../../feature_flags/mock_data';
import { parseUserIds, stringifyUserIds } from 'ee/user_lists/store/utils';
import createStore from 'ee/user_lists/store/show';
import UserList from 'ee/user_lists/components/user_list.vue';

jest.mock('ee/api');

Vue.use(Vuex);

describe('User List', () => {
  let wrapper;

  const click = testId => wrapper.find(`[data-testid="${testId}"]`).trigger('click');

  const findUserIds = () => wrapper.findAll('[data-testid="user-id"]');

  const destroy = () => wrapper?.destroy();

  const factory = () => {
    destroy();

    wrapper = mount(UserList, {
      store: createStore({ projectId: '1', userListIid: '2' }),
      propsData: {
        emptyStatePath: '/empty_state.svg',
      },
    });
  };

  describe('loading', () => {
    let resolveFn;

    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockReturnValue(
        new Promise(resolve => {
          resolveFn = resolve;
        }),
      );
      factory();
    });

    afterEach(() => {
      resolveFn();
    });

    it('shows a loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('success', () => {
    let userIds;

    beforeEach(() => {
      userIds = parseUserIds(userList.user_xids);
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: userList });
      factory();

      return wrapper.vm.$nextTick();
    });

    it('requests the user list on mount', () => {
      expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
    });

    it('shows the list name', () => {
      expect(wrapper.find('h3').text()).toBe(userList.name);
    });

    it('shows an add users button', () => {
      expect(wrapper.find('[data-testid="add-users"]').text()).toBe('Add Users');
    });

    it('shows a row for every id', () => {
      expect(wrapper.findAll('[data-testid="user-id-row"]')).toHaveLength(userIds.length);
    });

    it('shows one id on each row', () => {
      findUserIds().wrappers.forEach((w, i) => expect(w.text()).toBe(userIds[i]));
    });

    it('shows a delete button for every row', () => {
      expect(wrapper.findAll('[data-testid="delete-user-id"]')).toHaveLength(userIds.length);
    });

    describe('adding users', () => {
      const newIds = ['user3', 'user4', 'user5', 'test', 'example', 'foo'];
      let receivedUserIds;
      let parsedReceivedUserIds;

      beforeEach(async () => {
        Api.updateFeatureFlagUserList.mockResolvedValue(userList);
        click('add-users');
        await wrapper.vm.$nextTick();
        wrapper.find('#add-user-ids').setValue(`${stringifyUserIds(newIds)},`);
        click('confirm-add-user-ids');
        await wrapper.vm.$nextTick();
        [[, { user_xids: receivedUserIds }]] = Api.updateFeatureFlagUserList.mock.calls;
        parsedReceivedUserIds = parseUserIds(receivedUserIds);
      });

      it('should add user IDs to the user list', () => {
        newIds.forEach(id => expect(receivedUserIds).toContain(id));
      });

      it('should not remove existing user ids', () => {
        userIds.forEach(id => expect(receivedUserIds).toContain(id));
      });

      it('should not submit empty IDs', () => {
        parsedReceivedUserIds.forEach(id => expect(id).not.toBe(''));
      });

      it('should not create duplicate entries', () => {
        expect(uniq(parsedReceivedUserIds)).toEqual(parsedReceivedUserIds);
      });

      it('should display the new IDs', () => {
        const userIdWrappers = findUserIds();
        newIds.forEach(id => {
          const userIdWrapper = userIdWrappers.wrappers.find(w => w.text() === id);
          expect(userIdWrapper.exists()).toBe(true);
        });
      });
    });

    describe('deleting users', () => {
      let receivedUserIds;

      beforeEach(async () => {
        Api.updateFeatureFlagUserList.mockResolvedValue(userList);
        click('delete-user-id');
        await wrapper.vm.$nextTick();
        [[, { user_xids: receivedUserIds }]] = Api.updateFeatureFlagUserList.mock.calls;
      });

      it('should remove the ID clicked', () => {
        expect(receivedUserIds).not.toContain(userIds[0]);
      });

      it('should not display the deleted user', () => {
        const userIdWrappers = findUserIds();
        const userIdWrapper = userIdWrappers.wrappers.find(w => w.text() === userIds[0]);
        expect(userIdWrapper).toBeUndefined();
      });
    });
  });

  describe('error', () => {
    const findAlert = () => wrapper.find(GlAlert);

    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockRejectedValue();
      factory();

      return wrapper.vm.$nextTick();
    });

    it('displays the alert message', () => {
      const alert = findAlert();
      expect(alert.text()).toBe('Something went wrong on our end. Please try again!');
    });

    it('can dismiss the alert', async () => {
      const alert = findAlert();
      alert.find('button').trigger('click');

      await wrapper.vm.$nextTick();

      expect(alert.exists()).toBe(false);
    });
  });

  describe('empty list', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: { ...userList, user_xids: '' } });
      factory();

      return wrapper.vm.$nextTick();
    });

    it('displays an empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });
});
