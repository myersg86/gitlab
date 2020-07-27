import Cookies from 'js-cookie';
import { sortBy } from 'lodash';
import Flash from '~/flash';
import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { BoardType } from '~/boards/constants';
import * as types from './mutation_types';
import boardStore from '~/boards/stores/boards_store';

import projectBoardQuery from '../queries/project_board.query.graphql';
import groupBoardQuery from '../queries/group_board.query.graphql';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

const gqlClient = createDefaultClient();

export default {
  setInitialBoardData: ({ commit }, data) => {
    commit(types.SET_INITIAL_BOARD_DATA, data);
  },

  fetchLists: ({ commit, state, dispatch }) => {
    const { endpoints, boardType } = state;
    const { fullPath, boardId } = endpoints;

    const query = boardType === BoardType.group ? groupBoardQuery : projectBoardQuery;

    const variables = {
      fullPath,
      boardId: `gid://gitlab/Board/${boardId}`,
    };

    return gqlClient
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        let { lists } = data[boardType]?.board;
        // Temporarily using positionning logic from boardStore
        lists = lists.nodes.map(list =>
          boardStore.updateListPosition({
            ...list,
            id: getIdFromGraphQLId(list.id),
          }),
        );
        commit(types.RECEIVE_LISTS, sortBy(lists, 'position'));
        dispatch('showWelcomeList');
      })
      .catch(() => {
        Flash(__('An error occurred while fetching the board lists. Please try again.'));
      });
  },

  addList: ({ state, commit }, list) => {
    const lists = state.boardLists;
    // Temporarily using positionning logic from boardStore
    lists.push(boardStore.updateListPosition(list));
    commit(types.RECEIVE_LISTS, sortBy(lists, 'position'));
  },

  showWelcomeList: ({ state, dispatch }) => {
    if (
      state.boardLists.filter(list => list.type !== 'backlog' && list.type !== 'closed')[0] ||
      parseBoolean(Cookies.get('issue_board_welcome_hidden')) ||
      state.disabled
    ) {
      return;
    }
    dispatch('addList', {
      id: 'blank',
      list_type: 'blank',
      title: __('Welcome to your Issue Board!'),
      position: 0,
    });
  },

  showPromotionList: () => {},

  generateDefaultLists: () => {
    notImplemented();
  },

  createList: () => {
    notImplemented();
  },

  updateList: () => {
    notImplemented();
  },

  deleteList: () => {
    notImplemented();
  },

  fetchIssuesForList: () => {
    notImplemented();
  },

  moveIssue: () => {
    notImplemented();
  },

  createNewIssue: () => {
    notImplemented();
  },

  fetchBacklog: () => {
    notImplemented();
  },

  bulkUpdateIssues: () => {
    notImplemented();
  },

  fetchIssue: () => {
    notImplemented();
  },

  toggleIssueSubscription: () => {
    notImplemented();
  },

  showPage: () => {
    notImplemented();
  },

  toggleEmptyState: () => {
    notImplemented();
  },
};
