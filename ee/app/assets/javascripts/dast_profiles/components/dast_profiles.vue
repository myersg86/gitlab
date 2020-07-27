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
      siteProfiles: {
        list: [],
        pageInfo: {},
      },
    };
  },
  apollo: {
    siteProfiles: {
      query: dastSiteProfilesQuery,
      variables() {
        return {
          // @TODO - inject path
          fullPath: '/inject-project/path/here',
          first: 10,
        };
      },
      update({ project: { siteProfiles } }) {
        const { edges = [], pageInfo = {} } = siteProfiles;
        const list = edges.map(({ node }) => node);

        return {
          list,
          pageInfo,
        };
      },
      // @TODO - error handling / Sentry ?
      error: () => {},
    },
  },
  computed: {
    hasMoreSiteProfiles() {
      return this.siteProfiles.pageInfo.hasNextPage;
    },
  },
  methods: {
    fetchMoreProfiles() {
      const {
        siteProfiles: { pageInfo },
      } = this;

      this.$apollo.queries.siteProfiles.fetchMore({
        variables: { after: pageInfo.endCursor },
        // @TODO - check specs about `updateQuery` and clean up code below
        updateQuery: (previousResult, { fetchMoreResult }) => {
          const newResult = { ...fetchMoreResult };
          const previousEdges = previousResult.project.siteProfiles.edges;
          const newEdges = newResult.project.siteProfiles.edges;

          newResult.project.siteProfiles.edges = [...previousEdges, ...newEdges];

          return newResult;
        },
      });
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

        <profiles-list
          @loadMorePages="fetchMoreProfiles"
          :profiles="siteProfiles.list"
          :has-more-pages="hasMoreSiteProfiles"
        />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
