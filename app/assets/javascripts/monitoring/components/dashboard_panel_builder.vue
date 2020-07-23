<script>
import { mapActions, mapState } from 'vuex';
import { GlCard, GlForm, GlFormGroup, GlFormTextarea, GlButton, GlAlert } from '@gitlab/ui';
import DashboardPanel from './dashboard_panel.vue';

const initialYml = `title:
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
      ymlModel: this.yml || initialYml,
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
    if (this.ymlModel !== initialYml) {
      this.fetchPanelPreview(this.ymlModel);
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', ['fetchPanelPreview']),
    onSubmit() {
      this.fetchPanelPreview(this.ymlModel);
    },
  },
};
</script>
<template>
  <div>
    <gl-card>
      <template #header>
        <h2 class="gl-font-size-h2 gl-my-3">{{ s__('Metrics|Define and preview panel') }}</h2>
      </template>
      <template #default>
        <gl-form @submit.prevent.stop="onSubmit">
          <gl-form-group
            :label="s__('Metrics|Panel YAML')"
            :description="s__('Metrics|Define panel YAML to preview panel.')"
            label-for="panel-yml-input"
          >
            <gl-form-textarea
              id="panel-yml-input"
              v-model="ymlModel"
              class="gl-h-200! gl-font-monospace! gl-font-size-monospace!"
            />
          </gl-form-group>
          <div class="gl-text-right">
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
          </div>
        </gl-form>
      </template>
    </gl-card>

    <gl-alert v-if="panelPreviewError" variant="warning" :dismissible="false">
      {{ panelPreviewError }}
    </gl-alert>

    <dashboard-panel :graph-data="panelPreviewGraphData" />
  </div>
</template>
