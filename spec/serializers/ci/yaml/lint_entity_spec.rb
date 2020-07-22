# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Yaml::LintEntity do
  describe '#represent' do
    let(:yaml_processor) { Gitlab::Ci::YamlProcessor.new_with_validation_errors(yaml_content) }

    subject(:serialized_linting_result) { described_class.new(yaml_processor).to_json }

    context 'when config is invalid' do
      let(:yaml_content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }

      it 'matches schema' do
        expect(serialized_linting_result).to match_schema('entities/yaml_lint')
      end
    end

    context 'when config is valid' do
      let(:yaml_content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

      it 'matches schema' do
        expect(serialized_linting_result).to match_schema('entities/yaml_lint')
      end
    end
  end
end
