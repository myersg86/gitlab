# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IssueTypeEnum do
  specify { expect(described_class.graphql_name).to eq('IssueIssueType') }

  it 'exposes all the existing issue type values' do
    expect(described_class.values.keys).to include(
      *%w[ISSUE INCIDENT]
    )
  end
end
