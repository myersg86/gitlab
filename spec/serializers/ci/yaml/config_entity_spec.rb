# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Yaml::ConfigEntity do
  describe '#represent' do
    let(:config) { Gitlab::Ci::YamlProcessor.new_with_validation_errors(yaml_content).config }

    subject(:serialized_config_result) { described_class.new(config).as_json.to_json }

    context 'when config is valid' do
      let(:yaml_content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

      it 'matches schema' do
        expect(serialized_config_result).to match_schema('entities/yaml_config')
      end
    end
  end
end
