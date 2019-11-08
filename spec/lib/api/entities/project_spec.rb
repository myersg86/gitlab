# frozen_string_literal: true

require 'spec_helper'

describe API::Entities::Project do
  let(:project) { create(:project) }

  subject { described_class.new(project).as_json }

  context 'when project has no project_features' do
    before do
      project.project_feature.destroy
      project.project_feature = nil
    end

    it 'returns access levels' do
      expect(subject[:issues_access_level]).to be_nil
    end
  end
end
