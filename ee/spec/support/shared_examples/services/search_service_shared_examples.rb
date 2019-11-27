# frozen_string_literal: true

RSpec.shared_examples 'EE search service shared examples' do |normal_results, elasticsearch_results|
  before do
    allow(Gitlab::CurrentSettings)
      .to receive(:search_using_elasticsearch?)
      .and_return(true)

    allow(Gitlab::CurrentSettings)
      .to receive(:elasticsearch_limit_indexing?)
      .and_return(true)

    allow(scope).to receive(:in_elasticsearch_index?).and_return(true) if scope
  end

  let(:params) { { search: '*' } }

  describe '#use_elasticsearch?' do
    subject { service.use_elasticsearch? }

    context 'when GitLab::CurrentSettings.search_using_elasticsearch? is false' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:search_using_elasticsearch?)
          .with(scope: scope)
          .and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when elastcsearchable_scope is present and in_elasticsearch_index? is false' do
      before do
        allow(scope).to receive(:in_elasticsearch_index?).and_return(false) if scope
      end

      # Since the presence or absence of elasticsearchable_scope is defined in
      # the tests including the shared examples we need to do conditionally
      # assert in these tests based on it's presence or absence.
      it { is_expected.to eq(false) if scope }
    end

    context 'when elasticsearchable_scope is nil' do
      it { is_expected.to eq(true) if scope.nil? }
    end

    context 'when elasticsearchable_scope is present and intially_indexed? is true' do
      it { is_expected.to eq(true) if scope }
    end

    context 'when requesting basic_search' do
      let(:params) { { search: '*', basic_search: 'true' } }

      it 'returns false' do
        expect(Gitlab::CurrentSettings)
          .not_to receive(:search_using_elasticsearch?)

        expect(service.use_elasticsearch?).to eq(false)
      end
    end

    context 'when elasticsearch_limit_indexing is false' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:elasticsearch_limit_indexing?)
          .and_return(false)

        allow(scope).to receive(:in_elasticsearch_index?).and_return(false) if scope
      end

      it 'is always true since the user has opted to use Elasticsearch globally' do
        expect(subject).to eq(true)
      end
    end
  end

  describe '#execute' do
    subject { service.execute }

    it 'returns an Elastic result object when elasticsearch is enabled' do
      expect(Gitlab::CurrentSettings)
        .to receive(:search_using_elasticsearch?)
        .with(scope: scope)
        .and_return(true)

      is_expected.to be_a(elasticsearch_results)
    end

    it 'returns an ordinary result object when elasticsearch is disabled' do
      expect(Gitlab::CurrentSettings)
        .to receive(:search_using_elasticsearch?)
        .with(scope: scope)
        .and_return(false)

      is_expected.to be_a(normal_results)
    end
  end
end
