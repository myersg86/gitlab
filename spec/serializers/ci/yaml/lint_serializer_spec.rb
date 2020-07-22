# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Yaml::LintSerializer do
  describe '#represent' do
    let(:yaml_content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }
    let(:yaml_processor) { Gitlab::Ci::YamlProcessor.new_with_validation_errors(yaml_content) }

    subject(:serialized_linting_result) { described_class.new.represent(yaml_processor) }

    it 'serializes with lint entity' do
      expect(serialized_linting_result).to include(:valid, :errors, :config)
    end
  end
end
