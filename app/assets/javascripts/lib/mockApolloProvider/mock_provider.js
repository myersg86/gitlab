import { ApolloClient } from 'apollo-client';
import VueApollo from 'vue-apollo';
import { MockLink } from './mock_link';

export default function createMockProvider(mocks) {
  const mockClient = new ApolloClient({
    link: new MockLink(mocks || []),
  });

  return new VueApollo({
    defaultClient: mockClient,
  });
}
