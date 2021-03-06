# frozen_string_literal: true

require 'spec_helper'

describe Types::BaseField do
  context 'when considering complexity' do
    let(:resolver) do
      Class.new(described_class) do
        def self.resolver_complexity(args, child_complexity:)
          2 if args[:foo]
        end

        def self.complexity_multiplier(args)
          0.01
        end
      end
    end

    it 'defaults to 1' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

      expect(field.to_graphql.complexity).to eq 1
    end

    describe '#base_complexity' do
      context 'with no gitaly calls' do
        it 'defaults to 1' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

          expect(field.base_complexity).to eq 1
        end
      end

      context 'with a gitaly call' do
        it 'adds 1 to the default value' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true)

          expect(field.base_complexity).to eq 2
        end
      end
    end

    it 'has specified value' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

      expect(field.to_graphql.complexity).to eq 12
    end

    context 'when field has a resolver' do
      context 'when a valid complexity is already set' do
        let(:field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: resolver, complexity: 2, max_page_size: 100, null: true) }

        it 'uses this complexity' do
          expect(field.to_graphql.complexity).to eq 2
        end
      end

      context 'and is a connection' do
        let(:field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: resolver, max_page_size: 100, null: true) }

        it 'sets complexity depending on arguments for resolvers' do
          expect(field.to_graphql.complexity.call({}, {}, 2)).to eq 4
          expect(field.to_graphql.complexity.call({}, { first: 50 }, 2)).to eq 3
        end

        it 'sets complexity depending on number load limits for resolvers' do
          expect(field.to_graphql.complexity.call({}, { first: 1 }, 2)).to eq 2
          expect(field.to_graphql.complexity.call({}, { first: 1, foo: true }, 2)).to eq 4
        end
      end

      context 'and is not a connection' do
        it 'sets complexity as normal' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, max_page_size: 100, null: true)

          expect(field.to_graphql.complexity.call({}, {}, 2)).to eq 2
          expect(field.to_graphql.complexity.call({}, { first: 50 }, 2)).to eq 2
        end
      end
    end

    context 'calls_gitaly' do
      context 'for fields with a resolver' do
        it 'adds 1 if true' do
          with_gitaly_field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, null: true, calls_gitaly: true)
          without_gitaly_field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, null: true)
          base_result = without_gitaly_field.to_graphql.complexity.call({}, {}, 2)

          expect(with_gitaly_field.to_graphql.complexity.call({}, {}, 2)).to eq base_result + 1
        end
      end

      context 'for fields without a resolver' do
        it 'adds 1 if true' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true)

          expect(field.to_graphql.complexity).to eq 2
        end
      end

      it 'defaults to false' do
        field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

        expect(field.base_complexity).to eq Types::BaseField::DEFAULT_COMPLEXITY
      end

      context 'with declared constant complexity value' do
        it 'has complexity set to that constant' do
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

          expect(field.to_graphql.complexity).to eq 12
        end

        it 'does not raise an error even with Gitaly calls' do
          allow(Gitlab::GitalyClient).to receive(:get_request_count).and_return([0, 1])
          field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

          expect(field.to_graphql.complexity).to eq 12
        end
      end
    end

    describe '#visible?' do
      context 'and has a feature_flag' do
        let(:flag) { :test_feature }
        let(:field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE, feature_flag: flag, null: false) }
        let(:context) { {} }

        it 'returns false if the feature is not enabled' do
          stub_feature_flags(flag => false)

          expect(field.visible?(context)).to eq(false)
        end

        it 'returns true if the feature is enabled' do
          expect(field.visible?(context)).to eq(true)
        end

        context 'falsey feature_flag values' do
          using RSpec::Parameterized::TableSyntax

          where(:flag, :feature_value, :visible) do
            ''  | false | true
            ''  | true  | true
            nil | false | true
            nil | true  | true
          end

          with_them do
            it 'returns the correct value' do
              stub_feature_flags(flag => feature_value)

              expect(field.visible?(context)).to eq(visible)
            end
          end
        end
      end
    end
  end

  describe '#description' do
    context 'feature flag given' do
      let(:field) { described_class.new(name: 'test', type: GraphQL::STRING_TYPE, feature_flag: flag, null: false, description: 'Test description') }
      let(:flag) { :test_flag }

      it 'prepends the description' do
        expect(field.description). to eq 'Test description. Available only when feature flag `test_flag` is enabled'
      end

      context 'falsey feature_flag values' do
        using RSpec::Parameterized::TableSyntax

        where(:flag, :feature_value) do
          ''  | false
          ''  | true
          nil | false
          nil | true
        end

        with_them do
          it 'returns the correct description' do
            expect(field.description).to eq('Test description')
          end
        end
      end
    end
  end

  describe '`deprecated` property' do
    def test_field(args = {})
      base_args = { name: 'test', type: GraphQL::STRING_TYPE, null: true }

      described_class.new(**base_args.merge(args))
    end

    describe 'validations' do
      it 'raises an informative error if `deprecation_reason` is used' do
        expect { test_field(deprecation_reason: 'foo') }.to raise_error(
          ArgumentError,
          'Use `deprecated` property instead of `deprecation_reason`. ' \
          'See https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-fields'
        )
      end

      it 'raises an error if a required property is missing', :aggregate_failures do
        expect { test_field(deprecated: { milestone: '1.10' }) }.to raise_error(
          ArgumentError,
          'Please provide a `reason` within `deprecated`'
        )
        expect { test_field(deprecated: { reason: 'Deprecation reason' }) }.to raise_error(
          ArgumentError,
          'Please provide a `milestone` within `deprecated`'
        )
      end

      it 'raises an error if milestone is not a String', :aggregate_failures do
        expect { test_field(deprecated: { milestone: 1.10, reason: 'Deprecation reason' }) }.to raise_error(
          ArgumentError,
          '`milestone` must be a `String`'
        )
      end
    end

    it 'adds a formatted `deprecated_reason` to the field' do
      field = test_field(deprecated: { milestone: '1.10', reason: 'Deprecation reason' })

      expect(field.deprecation_reason).to eq('Deprecation reason. Deprecated in 1.10')
    end

    it 'appends to the description if given' do
      field = test_field(
        deprecated: { milestone: '1.10', reason: 'Deprecation reason' },
        description: 'Field description'
      )

      expect(field.description).to eq('Field description. Deprecated in 1.10: Deprecation reason')
    end

    it 'does not append to the description if it is absent' do
      field = test_field(deprecated: { milestone: '1.10', reason: 'Deprecation reason' })

      expect(field.description).to be_nil
    end

    it 'interacts well with the `feature_flag` property' do
      field = test_field(
        deprecated: { milestone: '1.10', reason: 'Deprecation reason' },
        description: 'Field description',
        feature_flag: 'foo_flag'
      )

      expect(field.description).to eq('Field description. Available only when feature flag `foo_flag` is enabled. Deprecated in 1.10: Deprecation reason')
    end
  end
end
