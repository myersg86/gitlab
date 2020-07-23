<script>
import { mapState } from 'vuex';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import routes from '../router/constants';
import DashboardPanelBuilder from '../components/dashboard_panel_builder.vue';

export default {
  components: {
    GlButton,
    DashboardPanelBuilder,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    yml: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('monitoringDashboard', ['panelPreviewYml']),
  },
  watch: {
    panelPreviewYml() {
      this.$router.push({
        name: this.$options.routes.PANEL_NEW_PAGE,
        query: {
          yml: this.panelPreviewYml,
        },
      });
    },
  },
  i18n: {
    backToDashboard: s__('Metrics|Back to dashboard'),
  },
  routes,
};
</script>
<template>
  <div class="gl-mt-5">
    <div class="gl-display-flex gl-align-items-baseline gl-mb-5">
      <gl-button
        v-gl-tooltip
        icon="go-back"
        :to="{
          name: $options.routes.DASHBOARD_PAGE,
          params: { dashboard: $route.params.dashboard },
        }"
        :aria-label="$options.i18n.backToDashboard"
        :title="$options.i18n.backToDashboard"
        class="gl-mr-5"
      />
      <h1 class="gl-font-size-h1 gl-my-0">{{ s__('Metrics|Add panel') }}</h1>
    </div>
    <dashboard-panel-builder :yml="yml" />
  </div>
</template>
