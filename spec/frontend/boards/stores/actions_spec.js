import actions from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('setInitialBoardData', () => {
  it('sets data object', () => {
    const mockData = {
      foo: 'bar',
      bar: 'baz',
    };

    return testAction(
      actions.setInitialBoardData,
      mockData,
      {},
      [{ type: types.SET_INITIAL_BOARD_DATA, payload: mockData }],
      [],
    );
  });
});

describe('showWelcomeList', () => {
  it('should dispatch addList action', done => {
    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'backlog' }, { type: 'closed' }],
    };

    const blankList = {
      id: 'blank',
      list_type: 'blank',
      title: 'Welcome to your Issue Board!',
      position: 0,
    };

    testAction(
      actions.showWelcomeList,
      {},
      state,
      [],
      [{ type: 'addList', payload: blankList }],
      done,
    );
  });
});

describe('generateDefaultLists', () => {
  expectNotImplemented(actions.generateDefaultLists);
});

describe('createList', () => {
  expectNotImplemented(actions.createList);
});

describe('updateList', () => {
  expectNotImplemented(actions.updateList);
});

describe('deleteList', () => {
  expectNotImplemented(actions.deleteList);
});

describe('fetchIssuesForList', () => {
  expectNotImplemented(actions.fetchIssuesForList);
});

describe('moveIssue', () => {
  expectNotImplemented(actions.moveIssue);
});

describe('createNewIssue', () => {
  expectNotImplemented(actions.createNewIssue);
});

describe('fetchBacklog', () => {
  expectNotImplemented(actions.fetchBacklog);
});

describe('bulkUpdateIssues', () => {
  expectNotImplemented(actions.bulkUpdateIssues);
});

describe('fetchIssue', () => {
  expectNotImplemented(actions.fetchIssue);
});

describe('toggleIssueSubscription', () => {
  expectNotImplemented(actions.toggleIssueSubscription);
});

describe('showPage', () => {
  expectNotImplemented(actions.showPage);
});

describe('toggleEmptyState', () => {
  expectNotImplemented(actions.toggleEmptyState);
});
