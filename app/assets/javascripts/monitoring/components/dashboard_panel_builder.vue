<script>
import { mapActions, mapState } from 'vuex';
import { GlCard, GlForm, GlFormGroup, GlFormTextarea, GlButton, GlAlert } from '@gitlab/ui';
import DashboardPanel from './dashboard_panel.vue';

const defaultYml = `title:
y_label:
type: area-chart
metrics:
- query_range:
  label:
`;

export default {
  components: {
    GlCard,
    GlForm,
    GlFormGroup,
    GlFormTextarea,
    GlButton,
    GlAlert,
    DashboardPanel,
  },
  directives: {},
  props: {
    yml: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      ymlModel: this.yml || defaultYml,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'panelPreviewIsLoading',
      'panelPreviewError',
      'panelPreviewGraphData',
    ]),
  },
  mounted() {
    // Start fetching if data is not the default yml
    if (this.ymlModel !== defaultYml) {
      this.fetchPanelPreview(this.ymlModel);
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', ['fetchPanelPreview']),
    onSubmit(event) {
      event.stopPropagation();
      this.fetchPanelPreview(this.ymlModel);
    },
  },
};
</script>
<template>
  <div>
    <gl-card>
      <template #header>
        <h2 class="h4">{{ s__('Metrics|Define and preview panel') }}</h2>
      </template>
      <template #default>
        <gl-form @submit.prevent="onSubmit">
          <gl-form-group
            :label="s__('Metrics|Panel YAML')"
            :description="s__('Metrics|Define panel YAML to preview panel.')"
            label-for="panel-yml-input"
          >
            <gl-form-textarea
              id="panel-yml-input"
              v-model="ymlModel"
              class="gl-font-monospace! gl-font-size-monospace!"
              style="height: 200px;"
            />
          </gl-form-group>
          <gl-button
            ref="clipboardCopyBtn"
            variant="success"
            category="secondary"
            :data-clipboard-text="ymlModel"
            @click="$toast.show(s__('Metrics|Panel YAML copied'))"
          >
            {{ s__('Metrics|Copy YAML') }}
          </gl-button>
          <gl-button type="submit" variant="success" :disabled="panelPreviewIsLoading">
            {{ s__('Metrics|Preview panel') }}
          </gl-button>
        </gl-form>
      </template>
    </gl-card>

    <gl-alert v-if="panelPreviewError" variant="warning" :dismissible="false">
      {{ panelPreviewError }}
    </gl-alert>

    <dashboard-panel :graph-data="panelPreviewGraphData" />
  </div>
</template>
