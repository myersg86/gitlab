import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import flash from '~/flash';

export const fetchIssuables = ({ dispatch }, { endpoint, params }) => {
  dispatch('setLoading', true);

  return axios.get(endpoint, params)
    .then((data) => {
      return data;
    })
    .catch(() => {
      return flash(__('An error occurred while loading issues'));
    });
};
