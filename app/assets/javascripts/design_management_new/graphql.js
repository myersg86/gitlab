import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { uniqueId } from 'lodash';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';
import activeDiscussionQuery from './graphql/queries/active_discussion.query.graphql';
import designListQuery from './graphql/queries/get_design_list.query.graphql';
import typeDefs from './graphql/typedefs.graphql';

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    updateActiveDiscussion: (_, { id = null, source }, { cache }) => {
      const data = cache.readQuery({ query: activeDiscussionQuery });
      data.activeDiscussion = {
        __typename: 'ActiveDiscussion',
        id,
        source,
      };
      cache.writeQuery({ query: activeDiscussionQuery, data });
    },
    designManagementMove(_, { id, from, to }, { cache }) {
      const data = cache.readQuery({
        query: designListQuery,
        variables: { fullPath: 'h5bp/html5-boilerplate', iid: '43', atVersion: null },
      });
      const designs = data.project.issue.designCollection.designs.edges;
      designs.splice(to, 0, designs.splice(from, 1)[0]);
      cache.writeQuery({
        query: designListQuery,
        variables: { fullPath: 'h5bp/html5-boilerplate', iid: '43', atVersion: null },
        data,
      });
    },
  },
};

const defaultClient = createDefaultClient(
  resolvers,
  // This config is added temporarily to resolve an issue with duplicate design IDs.
  // Should be removed as soon as https://gitlab.com/gitlab-org/gitlab/issues/13495 is resolved
  {
    cacheConfig: {
      dataIdFromObject: object => {
        // eslint-disable-next-line no-underscore-dangle, @gitlab/require-i18n-strings
        if (object.__typename === 'Design') {
          return object.id && object.image ? `${object.id}-${object.image}` : uniqueId();
        }
        return defaultDataIdFromObject(object);
      },
    },
    typeDefs,
  },
);

export default new VueApollo({
  defaultClient,
});
