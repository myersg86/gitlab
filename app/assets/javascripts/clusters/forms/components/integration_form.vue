<script>
import {
  GlFormGroup,
  GlFormInput,
  GlToggle,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  components: {
    GlFormGroup,
    GlToggle,
    GlFormInput,
    GlSprintf,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      toggleEnabled: true,
      envScope: '*',
      baseDomainField: '',
      externalIp: '',
    };
  },
  computed: {
    ...mapState([
      'enabled',
      'editable',
      'environmentScope',
      'baseDomain',
      'applicationIngressExternalIp',
    ]),
    formChanged() {
      if (
        this.enabled === this.toggleEnabled &&
        this.environmentScope === this.envScope &&
        this.baseDomain === this.baseDomainField
      ) {
        return false;
      }
      return true;
    },
  },
  mounted() {
    this.toggleEnabled = this.enabled;
    this.envScope = this.environmentScope;
    this.baseDomainField = this.baseDomain;
    this.externalIp = this.applicationIngressExternalIp;
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
      id="environment-scope"
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
      <gl-form-input v-model="envScope" class="col-md-6" type="text" />
    </gl-form-group>

    <gl-form-group
      id="base-domain"
      :label="s__('ClusterIntegration|Base domain')"
      label-size="sm"
      label-for="cluster_base_domain"
    >
      <input
        id="cluster_base_domain"
        name="cluster[base_domain]"
        type="hidden"
        data-qa-selector="base_domain_field"
        :value="baseDomainField"
        data-testid="hidden-base-domain-input"
      />
      <gl-form-input v-model="baseDomainField" class="col-md-6" type="text" />
      <div class="form-text text-muted">
        <gl-sprintf
          :message="
            s__(
              'ClusterIntegration|Specifying a domain will allow you to use Auto Review Apps and Auto Deploy stages for %{linkStart}Auto DevOps.%{linkEnd} The domain should have a wildcard DNS configured matching the domain. ',
            )
          "
        >
          <template #link="{ content }">
            <gl-link href="../../../../help/topics/autodevops/index.md" target="_blank">
              {{ content }}
            </gl-link>
          </template>
          <template #link2="{ content }">
            <gl-link
              href="../../../../help/user/clusters/applications.md#pointing-your-dns-at-the-external-endpoint"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
        <div class="js-ingress-domain-help-text">
          <template v-if="applicationIngressExternalIp">
            <template>
              {{ s__('ClusterIntegration|Alternatively, ') }}
            </template>
            <gl-sprintf class="js-ingress-domain-snippet" :message="__('%{externalIp}.nip.io')">
              <template #externalIp>{{ externalIp }}</template>
            </gl-sprintf>
            <template>{{
              s__('ClusterIntegration|can be used instead of a custom domain. ')
            }}</template>
          </template>
        </div>
        <gl-sprintf :message="s__('ClusterIntegration|%{linkStart}More information%{linkEnd}')">
          <template #link="{ content }">
            <gl-link
              href="../../../../help/user/clusters/applications.md#pointing-your-dns-at-the-external-endpoint"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </gl-form-group>
    <div v-if="editable" class="form group gl-display-flex gl-justify-content-end">
      <button
        class="btn btn-success"
        type="submit"
        name="commit"
        value="Save changes"
        :disabled="!formChanged"
        data-qa-selector="save_changes_button"
        data-disable-with="Save changes"
      >
        {{ s__('ClusterIntegration|Save changes') }}
      </button>
    </div>
  </div>
</template>
