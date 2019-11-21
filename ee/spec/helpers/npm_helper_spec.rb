# frozen_string_literal: true

require 'spec_helper'

describe NpmHelper do
  describe 'npmrc content' do
    it 'creates the content with the correct gitlab paths' do
      registry_path = 'api/v4/packages/npm/'
      project_path = 'api/v4/projects/'

      expect(generate_npmrc_template_content).to include(registry_path, project_path)
    end

    it 'creates the content with supplied registry and project url' do
      registry_url = 'my-registry'
      project_url = 'my-project'

      expect(npmrc_template(registry_url, project_url)).to include(registry_url, project_url)
    end
  end
end
