# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IssueResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:issue) { create(:issue) }

    context 'when unauthenticated' do
      let_it_be(:current_user) { nil }

      it 'raise ResourceNotAvailable' do
        expect { 
          resolve_issue({id: issue.to_global_id.to_s} ) 
        }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when authenticated as normal user' do
      let_it_be(:current_user) { create(:user) }

      it 'raise ResourceNotAvailable' do
        expect { 
          resolve_issue({id: issue.to_global_id.to_s} ) 
        }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when authenticated as admin' do
      let_it_be(:current_user) { create(:user, :admin) }

      context 'when an ID is not provided' do
        it 'raises an ArgumentError' do
          expect { 
            resolve_issue({}) 
          }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
        end
      end

      context 'by ID' do
        it 'returns the correct issue' do
          expect(
            resolve_issue({id: issue.to_global_id.to_s})
          ).to eq(issue)
        end
      end
    end
  end

  private

  def resolve_issue(args = {}, ctx = { current_user: current_user })
    resolve(described_class, args: args, ctx: ctx)
  end
end
