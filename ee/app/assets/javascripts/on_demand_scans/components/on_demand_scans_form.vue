<script>
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import {
  GlAlert,
  GlButton,
  GlCard,
  GlForm,
  GlFormGroup,
  GlIcon,
  GlLink,
  GlNewDropdown,
  GlNewDropdownItem,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import runDastScanMutation from '../graphql/dast_on_demand_scan_create.mutation.graphql';
import { SCAN_TYPES } from '../constants';

const initField = value => ({
  value,
  state: null,
  feedback: null,
});

export default {
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlForm,
    GlFormGroup,
    GlIcon,
    GlLink,
    GlNewDropdown,
    GlNewDropdownItem,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  // apollo: {
  //   siteProfiles: {
  //     query: null,
  //     variables() {
  //       return {
  //         fullPath: this.projectPath,
  //       };
  //     },
  //     skip() {
  //       return true;
  //     },
  //   },
  // },
  props: {
    helpPagePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    profilesLibraryPath: {
      type: String,
      required: true,
    },
    newSiteProfilePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      siteProfiles: [],
      form: {
        scanType: initField(SCAN_TYPES.PASSIVE),
        branch: initField(this.defaultBranch),
        siteProfile: initField(null),
      },
      loading: false,
      errors: [],
      showAlert: false,
    };
  },
  computed: {
    formData() {
      return {
        projectPath: this.projectPath,
        ...Object.fromEntries(Object.entries(this.form).map(([key, { value }]) => [key, value])),
      };
    },
    formHasErrors() {
      return Object.values(this.form).some(({ state }) => state === false);
    },
    someFieldEmpty() {
      return Object.values(this.form).some(({ value }) => !value);
    },
    isSubmitDisabled() {
      return this.formHasErrors || this.someFieldEmpty;
    },
    selectedSiteProfile() {
      const selectedSiteProfileId = this.form.siteProfile.value;
      return selectedSiteProfileId === null
        ? null
        : this.siteProfiles.find(({ id }) => id === selectedSiteProfileId);
    },
    siteProfileText() {
      const { selectedSiteProfile } = this;
      return selectedSiteProfile
        ? `${selectedSiteProfile.name}: ${selectedSiteProfile.targetUrl}`
        : s__('OnDemandScans|Select one of the existing profiles');
    },
  },
  methods: {
    setSiteProfile({ id }) {
      this.form.siteProfile.value = id;
    },
    onSubmit() {
      this.loading = true;
      this.dismissAlert();

      this.$apollo
        .mutate({
          mutation: runDastScanMutation,
          variables: this.formData,
        })
        .then(({ data: { runDastScan: { pipelineUrl, errors } } }) => {
          if (errors?.length) {
            this.setErrors(errors);
            this.loading = false;
          } else {
            redirectTo(pipelineUrl);
          }
        })
        .catch(e => {
          Sentry.captureException(e);
          this.setErrors();
          this.loading = false;
        });
    },
    setErrors(errors = []) {
      this.errors = errors;
      this.showAlert = true;
    },
    dismissAlert() {
      this.errors = [];
      this.showAlert = false;
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <header class="gl-mb-6">
      <h2>{{ s__('OnDemandScans|New on-demand DAST scan') }}</h2>
      <p>
        <gl-icon name="information-o" class="gl-vertical-align-text-bottom gl-text-gray-600" />
        <gl-sprintf
          :message="
            s__(
              'OnDemandScans|On-demand scans run outside the DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}',
            )
          "
        >
          <template #learnMoreLink="{ content }">
            <gl-link :href="helpPagePath">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-alert v-if="showAlert" variant="danger" class="gl-mb-5" data-testid="on-demand-scan-error" @dismiss="dismissAlert">
      {{ s__('OnDemandScans|Could not run the scan. Please try again.') }}
      <ul v-if="errors.length">
        <li v-for="error in errors" :key="error" v-text="error"></li>
      </ul>
    </gl-alert>

    <gl-card>
      <template #header>
        <strong class="gl-font-lg">{{ s__('OnDemandScans|Scanner settings') }}</strong>
      </template>

      <gl-form-group class="gl-mt-4">
        <template #label>
          {{ s__('OnDemandScans|Scan mode') }}
          <gl-icon
            v-gl-tooltip.hover
            name="information-o"
            class="gl-vertical-align-text-bottom gl-text-gray-600"
            :title="s__('OnDemandScans|Only a passive scan can be performed on demand.')"
          />
        </template>
        {{ s__('OnDemandScans|Passive') }}
      </gl-form-group>

      <gl-form-group class="gl-mt-7 gl-mb-2">
        <template #label>
          {{ s__('OnDemandScans|Attached branch') }}
          <gl-icon
            v-gl-tooltip.hover
            name="information-o"
            class="gl-vertical-align-text-bottom gl-text-gray-600"
            :title="s__('OnDemandScans|Attached branch is where the scan job runs.')"
          />
        </template>
        {{ defaultBranch }}
      </gl-form-group>
    </gl-card>

    <gl-card>
      <template #header>
        <div class="row">
          <div class="col-7">
            <strong class="gl-font-lg">{{ s__('OnDemandScans|Site profiles') }}</strong>
          </div>
          <div class="col-5 gl-text-right">
            <gl-button
              :href="siteProfiles.length ? profilesLibraryPath : '#'"
              :disabled="!siteProfiles.length"
              variant="success"
              category="secondary"
              size="small"
            >
              {{ s__('OnDemandScans|Manage profiles') }}
            </gl-button>
          </div>
        </div>
      </template>
      <gl-form-group v-if="siteProfiles.length">
        <template #label>
          {{ s__('OnDemandScans|Use existing site profile') }}
        </template>
        <gl-new-dropdown
          v-model="form.siteProfile.value"
          :text="siteProfileText"
          class="mw-460"
          data-testid="site-profiles-dropdown"
        >
          <gl-new-dropdown-item
            v-for="siteProfile in siteProfiles"
            :key="siteProfile.id"
            :is-checked="form.siteProfile.value === siteProfile.id"
            is-check-item
            @click="setSiteProfile(siteProfile)"
          >
            {{ siteProfile.name }}
          </gl-new-dropdown-item>
        </gl-new-dropdown>
        <template v-if="selectedSiteProfile">
          <hr />
          <div class="row" data-testid="site-profile-summary">
            <div class="col-md-6">
              <div class="row">
                <div class="col-md-3">{{ s__('DastProfiles|Target URL') }}:</div>
                <div class="col-md-9 gl-font-weight-bold">
                  {{ selectedSiteProfile.targetUrl }}
                </div>
              </div>
            </div>
          </div>
        </template>
      </gl-form-group>
      <template v-else>
        <p class="gl-text-gray-700">
          {{
            s__(
              'OnDemandScans|No profile yet. In order to create a new scan, you need to have at least one completed site profile.',
            )
          }}
        </p>
        <gl-button :href="newSiteProfilePath" variant="success" category="secondary">
          {{ s__('OnDemandScans|Create a new site profile') }}
        </gl-button>
      </template>
    </gl-card>

    <div class="gl-mt-6 gl-pt-6">
      <gl-button
        type="submit"
        variant="success"
        class="js-no-auto-disable"
        :disabled="isSubmitDisabled"
        :loading="loading"
      >
        {{ s__('OnDemandScans|Run scan') }}
      </gl-button>
      <gl-button @click="$emit('cancel')">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
