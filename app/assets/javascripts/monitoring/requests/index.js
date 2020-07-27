import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';
import { PROMETHEUS_TIMEOUT } from '../constants';

const backOffRequest = makeRequestCallback =>
  backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.NO_CONTENT) {
          next();
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  }, PROMETHEUS_TIMEOUT);

export const getDashboard = (dashboardEndpoint, params) =>
  backOffRequest(() => axios.get(dashboardEndpoint, { params })).then(
    axiosResponse => axiosResponse.data,
  );

export const getPrometheusQueryData = (prometheusEndpoint, params) =>
  backOffRequest(() => axios.get(prometheusEndpoint, { params }))
    .then(axiosResponse => axiosResponse.data)
    .then(prometheusResponse => prometheusResponse.data)
    .catch(error => {
      // Prometheus returns errors in specific cases
      // https://prometheus.io/docs/prometheus/latest/querying/api/#format-overview
      const { response = {} } = error;
      if (
        response.status === statusCodes.BAD_REQUEST ||
        response.status === statusCodes.UNPROCESSABLE_ENTITY ||
        response.status === statusCodes.SERVICE_UNAVAILABLE
      ) {
        const { data } = response;
        if (data?.status === 'error' && data?.error) {
          throw new Error(data.error);
        }
      }
      throw error;
    });

// eslint-disable-next-line no-unused-vars
export function getPanelJson(panelPreviewEndpoint, panelPreviewYml) {
  // TODO Use a real backend when it's available
  // https://gitlab.com/gitlab-org/gitlab/-/issues/228758

  // eslint-disable-next-line @gitlab/require-i18n-strings
  // return Promise.reject(new Error('API Not implemented.'));
  // TODO Use a real backend when it's available
  // return axios
  //   .get(panelPreviewEndpoint, { params: { panelPreviewYml } })
  //   .then(response => response.data)

  // TODO Remove mock
  return Promise.resolve().then(() => ({
    title: 'Memory Usage (Total)',
    type: 'area-chart',
    y_label: 'Total Memory Used (GB)',
    weight: 4,
    id: '4570deed516d0bf93fb42879004117009ab456ced27393ec8dce5b6960438132',
    metrics: [
      {
        id: 'system_metrics_kubernetes_container_memory_total',
        query_range:
          'avg(sum(container_memory_usage_bytes{container!="POD",pod=~"^{{ci_environment_slug}}-(.*)",namespace="{{kube_namespace}}"}) by (job)) without (job)  /1024/1024/1024     OR      avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^{{ci_environment_slug}}-(.*)",namespace="{{kube_namespace}}"}) by (job)) without (job)  /1024/1024/1024',
        label: 'Total (GB)',
        unit: 'GB',
        metric_id: 15,
        edit_path: null,
        prometheus_endpoint_path:
          '/root/autodevops-deploy/-/environments/29/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer%21%3D%22POD%22%2Cpod%3D~%22%5E%7B%7Bci_environment_slug%7D%7D-%28.%2A%29%22%2Cnamespace%3D%22%7B%7Bkube_namespace%7D%7D%22%7D%29+by+%28job%29%29+without+%28job%29++%2F1024%2F1024%2F1024+++++OR++++++avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%7B%7Bci_environment_slug%7D%7D-%28.%2A%29%22%2Cnamespace%3D%22%7B%7Bkube_namespace%7D%7D%22%7D%29+by+%28job%29%29+without+%28job%29++%2F1024%2F1024%2F1024',
      },
    ],
  }));
  // END TODO Remove mock
}
