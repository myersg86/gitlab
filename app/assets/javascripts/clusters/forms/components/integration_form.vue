<script>
import { GlFormGroup, GlFormInput, GlToggle, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormInput,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      toggleEnabled: true,
      envScope: '*',
    };
  },
  computed: {
    ...mapState(['enabled', 'editable', 'environmentScope']),
  },
  mounted() {
    this.toggleEnabled = this.enabled;
    this.envScope = this.environmentScope;
  },
};
</script>

<template>
  <div class="d-flex gl-flex-direction-column">
    <gl-form-group>
      <div class="gl-display-flex gl-align-items-center">
        <h4 class="gl-pr-3 gl-m-0 ">{{ s__('ClusterIntegration|GitLab Integration') }}</h4>
        <input
          id="cluster_enabled"
          class="js-project-feature-toggle-input"
          type="hidden"
          :value="toggleEnabled"
          name="cluster[enabled]"
          data-testid="hidden-toggle-input"
        />
        <div id="tooltipcontainer" class="js-cluster-enable-toggle-area">
          <gl-toggle
            v-model="toggleEnabled"
            v-gl-tooltip:tooltipcontainer
            class="gl-mb-0 js-project-feature-toggle"
            data-qa-selector="integration_status_toggle"
            :aria-describedby="__('Toggle Kubernetes cluster')"
            :disabled="!editable"
            :is_checked="toggleEnabled"
            :title="
              s__(
                'ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.',
              )
            "
          />
        </div>
      </div>
    </gl-form-group>

    <gl-form-group
      id="group-id"
      :label="s__('ClusterIntegration|Environment scope')"
      label-size="sm"
      label-for="cluster_environment_scope"
      :description="
        s__('ClusterIntegration|Choose which of your environments will use this cluster.')
      "
    >
      <input
        id="cluster_environment_scope"
        name="cluster[environment_scope]"
        type="hidden"
        :value="envScope"
        data-testid="hidden-environment-scope-input"
      />
      <gl-form-input class="col-md-6" v-model="envScope" type="text" />
    </gl-form-group>
  </div>
</template>
