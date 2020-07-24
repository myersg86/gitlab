<script>
import { GlButton, GlTab, GlTabs } from '@gitlab/ui';
import ProfilesList from './dast_profiles_list.vue';
import dastSiteProfilesQuery from '../graphql/dast_site_profiles.query.graphql';

export default {
  components: {
    GlButton,
    GlTab,
    GlTabs,
    ProfilesList,
  },
  props: {
    newDastSiteProfilePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      profiles: [
        {
          id: 1,
          profileName: 'Profile 1',
          targetUrl: 'http://example-1.com',
          validationStatus: 'Not validated',
        },
        {
          id: 2,
          profileName: 'Profile 1',
          targetUrl: 'http://example-1.com',
          validationStatus: 'Not validated',
        },
      ],
    };
  },
  apollo: {
    profiles_TEMP_DISABLED: {
      query: dastSiteProfilesQuery,
      variables() {
        return {
          // @TODO - inject path
          fullPath: '/inject-project/path/here',
        };
      },
      // @TODO - error handling
      error: () => {},
    },
  },
};
</script>

<template>
  <section>
    <header>
      <div class="gl-display-flex gl-align-items-center gl-pt-6 gl-pb-4">
        <h2 class="my-0">
          {{ s__('DastProfiles|Manage Profiles') }}
        </h2>
        <gl-button
          :href="newDastSiteProfilePath"
          category="primary"
          variant="success"
          class="gl-ml-auto"
        >
          {{ s__('DastProfiles|New Site Profile') }}
        </gl-button>
      </div>
      <p>
        {{
          s__(
            'DastProfiles|Save commonly used configurations for target sites and scan specifications as profiles. Use these with an on-demand scan.',
          )
        }}
      </p>
    </header>
    <!--    TODO: Create and switch to `gl-*` class-->
    <gl-tabs content-class="p-md-0">
      <gl-tab>
        <template #title>
          <span>{{ s__('DastProfiles|Site Profiles') }}</span>
        </template>

        <profiles-list :profiles="profiles" />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
