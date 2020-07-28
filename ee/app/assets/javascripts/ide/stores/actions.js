import * as yaml from 'js-yaml';
import * as types from './mutation_types';
import { registerSchemas } from '~/ide/utils';
import jsonOptions from '~/ide/lib/schemas/json';
import yamlOptions from '~/ide/lib/schemas/yaml';

export const fetchConfig = ({ state, commit, dispatch }) => {
  const configPath = '.gitlab/.gitlab-webide.yml';
  if (!state.entries[configPath]) return Promise.resolve();

  return dispatch('getFileData', { path: configPath, makeFileActive: false })
    .then(() => dispatch('getRawFileData', { path: configPath }))
    .then(raw => {
      const config = yaml.safeLoad(raw);

      commit(types.SET_CONFIG, config);
    });
};

export const registerSchemasFromConfig = ({ state }) => {
  const mapSchema = ({ uri, match }) => ({ uri, fileMatch: match });
  let { 'json.schemas': jsonSchemas = [], 'yaml.schemas': yamlSchemas = [] } = state.config;

  jsonSchemas = jsonSchemas.map(mapSchema);
  yamlSchemas = yamlSchemas.map(mapSchema);

  const jsonSettings = {
    language: 'json',
    options: { ...jsonOptions.options, schemas: jsonSchemas },
  };
  const yamlSettings = {
    language: 'yaml',
    options: { ...yamlOptions.options, schemas: yamlSchemas },
  };

  registerSchemas(jsonSettings, yamlSettings);
};

export * from '~/ide/stores/actions';
