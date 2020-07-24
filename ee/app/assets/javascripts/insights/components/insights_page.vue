<script>
import { isUndefined } from 'lodash';
import { mapActions, mapState } from 'vuex';

import InsightsConfigWarning from './insights_config_warning.vue';
import InsightsChart from './insights_chart.vue';

export default {
  components: {
    InsightsChart,
    InsightsConfigWarning,
  },
  props: {
    queryEndpoint: {
      type: String,
      required: true,
    },
    pageConfig: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('insights', ['chartData']),
    charts() {
      return this.pageConfig.charts;
    },
    chartKeys() {
      return this.charts.map(chart => chart.title);
    },
    storeKeys() {
      return Object.keys(this.chartData);
    },
    hasChartsConfigured() {
      return !isUndefined(this.charts) && this.charts.length > 0;
    },
  },
  watch: {
    pageConfig() {
      this.fetchCharts();
    },
  },
  mounted() {
    this.fetchCharts();
  },
  methods: {
    ...mapActions('insights', ['fetchChartData', 'initChartData']),
    fetchCharts() {
      if (this.hasChartsConfigured) {
        this.initChartData(this.chartKeys);

        this.charts.forEach(chart => this.fetchChartData({ endpoint: this.queryEndpoint, chart }));
      }
    },
    storePopulated() {
      return this.chartKeys.filter(key => this.storeKeys.includes(key)).length > 0;
    },
  },
};
</script>
<template>
  <div class="insights-page" data-qa-selector="insights_page">
    <div v-if="hasChartsConfigured" class="js-insights-page-container">
      <h4 class="text-center">{{ pageConfig.title }}</h4>
      <div class="insights-charts" data-qa-selector="insights_charts">
        <insights-chart
          v-for="({ loaded, type, description, data, error }, key, index) in chartData"
          :key="index"
          :loaded="loaded"
          :type="type"
          :title="key"
          :description="description"
          :data="data"
          :error="error"
        />
      </div>
    </div>
    <insights-config-warning
      v-else
      :title="__('There are no charts configured for this page')"
      :summary="
        __(
          'Please check the configuration file to ensure that a collection of charts has been declared.',
        )
      "
      image="illustrations/monitoring/getting_started.svg"
    />
  </div>
</template>
