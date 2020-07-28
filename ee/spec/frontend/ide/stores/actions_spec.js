import { createStore } from 'ee/ide/stores';
import services from '~/ide/services';
import { file } from 'jest/ide/helpers';
import { languages } from 'monaco-editor';

describe('EE IDE store actions', () => {
  let store;
  let state;

  beforeEach(() => {
    store = createStore();

    state = store.state;
    state.currentProjectId = 'gitlab-org/gitlab';
    state.currentBranchId = 'master';
    state.trees['gitlab-org/gitlab/master'] = { loading: false };
    state.entries = {
      '.gitlab/.gitlab-webide.yml': {
        ...file(),
        path: '.gitlab/.gitlab-webide.yml',
      },
    };

    jest.spyOn(services, 'getFileData').mockResolvedValue();
    jest.spyOn(services, 'getRawFileData').mockResolvedValue('a: b');
  });

  describe('fetchConfig', () => {
    it('fetches IDE config and sets it in state', () => {
      return store.dispatch('fetchConfig').then(() => {
        expect(services.getFileData).toHaveBeenCalled();
        expect(services.getRawFileData).toHaveBeenCalled();

        expect(state.config).toEqual({ a: 'b' });
      });
    });

    it('does nothing if .gitlab/.gitlab-webide.yml file does not exist in entries', () => {
      state.entries = {};

      return store.dispatch('fetchConfig').then(() => {
        expect(state.config).toEqual({});

        expect(services.getFileData).not.toHaveBeenCalled();
        expect(services.getRawFileData).not.toHaveBeenCalled();
      });
    });
  });

  describe('registerSchemasFromConfig', () => {
    it('registers schemas from config object in state', () => {
      state.config = {
        'yaml.schemas': [
          {
            uri: 'http://myserver/foo-schema.json',
            match: ['myfile.yml'],
          },
        ],
        'json.schemas': [
          {
            uri: 'http://myserver/bar-schema.json',
            match: ['myfile.json'],
          },
        ],
      };

      jest.spyOn(languages.json.jsonDefaults, 'setDiagnosticsOptions');
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');

      return store.dispatch('registerSchemasFromConfig').then(() => {
        expect(languages.json.jsonDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining({
            schemas: [
              {
                uri: 'http://myserver/bar-schema.json',
                fileMatch: ['myfile.json'],
              },
            ],
          }),
        );

        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining({
            schemas: [
              {
                uri: 'http://myserver/foo-schema.json',
                fileMatch: ['myfile.yml'],
              },
            ],
          }),
        );
      });
    });
  });
});
