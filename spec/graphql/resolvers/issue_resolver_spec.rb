# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::IssueResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:issue) { create(:issue) }

    context 'when an ID is not provided' do
      it 'raises an ArgumentError' do
        expect { resolve_issue }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'by ID' do
      it 'returns the correct issue' do
        expect(
          resolve_issue(id: issue.to_global_id)
        ).to eq(issue)
      end
    end
  end

  private

  def resolve_issue(args = {})
    sync(resolve(described_class, args: args))
  end
end
