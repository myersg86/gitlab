import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import VueApollo from 'vue-apollo';
import { MockLink } from './mock_link';

export default function createMockProvider(mocks, addTypename = false) {
  const mockClient = new ApolloClient({
    link: new MockLink(mocks || [], addTypename),
    cache: new InMemoryCache({ addTypename }),
  });

  return new VueApollo({
    defaultClient: mockClient,
  });
}
