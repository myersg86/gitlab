import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { decorateFiles } from '~/ide/lib/files';
import { createStore } from '~/ide/stores';

const TEST_BRANCH = 'test_branch';
const TEST_NAMESPACE = 'test_namespace';
const TEST_PROJECT_ID = `${TEST_NAMESPACE}/test_project`;
const TEST_PATH = 'src/foo.js';
const TEST_CONTENT = `Lorem ipsum dolar sit
Lorem ipsum dolar
Lorem ipsum
Lorem
`;

jest.mock('~/ide/ide_router');

describe('IDE store integration', () => {
  let store;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('with project and files', () => {
    beforeEach(() => {
      const { entries, treeList } = decorateFiles({
        data: ['src/', TEST_PATH, 'README.md'],
        projectId: TEST_PROJECT_ID,
        branchId: TEST_BRANCH,
      });

      Object.assign(entries[TEST_PATH], {
        raw: TEST_CONTENT,
      });

      store.replaceState({
        ...store.state,
        currentProjectId: TEST_PROJECT_ID,
        currentBranchId: TEST_BRANCH,
        trees: {
          [`${TEST_PROJECT_ID}/${TEST_BRANCH}`]: {
            tree: treeList,
          },
        },
        entries,
      });
    });

    it.each(['unstageChange', 'stageChange'])(
      'has no changes when file is deleted and readded then %p',
      action => {
        store.dispatch('deleteEntry', TEST_PATH);
        store.dispatch('createTempEntry', { name: TEST_PATH, type: 'blob' });
        store.dispatch('changeFileContent', { path: TEST_PATH, content: TEST_CONTENT });

        expect(store.state.changedFiles).toEqual([
          expect.objectContaining({
            path: TEST_PATH,
            tempFile: true,
            deleted: false,
          }),
        ]);

        expect(store.state.stagedFiles).toEqual([
          expect.objectContaining({
            path: TEST_PATH,
            deleted: true,
          }),
        ]);

        store.dispatch(action, TEST_PATH);

        expect(store.state.changedFiles).toEqual([]);
        expect(store.state.stagedFiles).toEqual([]);
        expect(store.state.entries[TEST_PATH]).toEqual(
          expect.objectContaining({
            tempFile: false,
            changed: false,
            staged: false,
          }),
        );
        expect(store.state.entries['src'].tree[0]).toEqual(
          expect.objectContaining({
            tempFile: false,
            changed: false,
            staged: false,
          }),
        );
      },
    );
  });
});
