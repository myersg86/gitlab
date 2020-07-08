# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::DeleteTagsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }
  let_it_be(:repository) { create(:container_repository, :root, project: project) }

  let(:params) { { tags: tags } }
  let(:service) { described_class.new(project, user, params) }

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')

    stub_container_registry_tags(
      repository: repository.path,
      tags: %w(latest A Ba Bb C D E))
  end

  describe '#execute' do
    let(:tags) { %w[A] }

    subject { service.execute(repository) }

    context 'without throttling' do
      before do
        stub_application_setting(container_registry_expiration_policies_throttling: false)
      end

      it_behaves_like 'deleting container tags'
    end

    context 'with throttling enabled' do
      let(:service_timeout) { 60 }

      before do
        stub_application_setting(container_registry_expiration_policies_throttling: true)
        stub_application_setting(container_registry_delete_tags_service_timeout: service_timeout)
      end

      it_behaves_like 'deleting container tags'

      context 'with permissions' do
        before do
          project.add_developer(user)
        end

        context 'hitting the service timeout' do
          let(:service_timeout) { 0.5 }

          before do
            allow(repository).to receive(:delete_tag_by_name).with('A').and_wrap_original do |m, *args|
              sleep(1.second)
              m.call(*args)
            end
          end

          context 'with fast delete' do
            before do
              allow(repository.client).to receive(:supports_tag_delete?).and_return(true)
            end

            it { is_expected.to include(status: :error, message: 'Timeout while deleting tags') }

            it 'tracks the error' do
              expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
                instance_of(Timeout::Error),
                container_repository_id: repository.id, tags_count: tags.size
              )

              subject
            end
          end

          context 'with slow delete' do
            before do
              allow(repository.client).to receive(:supports_tag_delete?).and_return(false)
            end

            it_behaves_like 'deleting with slow delete container tags', %w[A]
          end
        end

        context 'with service timeout set to' do
          before do
            allow(repository).to receive(:delete_tag_by_name).with('A').and_wrap_original do |m, *args|
              sleep(1.second)
              m.call(*args)
            end
            allow(repository.client).to receive(:supports_tag_delete?).and_return(true)
          end

          context '0' do
            let(:service_timeout) { 0 }

            it_behaves_like 'deleting with fast delete container tags', %w[A]
          end

          context 'nil' do
            let(:service_timeout) { 0 }

            it_behaves_like 'deleting with fast delete container tags', %w[A]
          end
        end
      end
    end
  end

  private

  def stub_delete_reference_request(tag, status = 200)
    stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/tags/reference/#{tag}")
      .to_return(status: status, body: '')
  end

  def stub_put_manifest_request(tag, status = 200, headers = { 'docker-content-digest' => 'sha256:dummy' })
    stub_request(:put, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: status, body: '', headers: headers)
  end

  def stub_tag_digest(tag, digest)
    stub_request(:head, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: 200, body: "", headers: { 'docker-content-digest' => digest })
  end

  def stub_digest_config(digest, created_at)
    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:blob)
      .with(repository.path, digest, nil) do
      { 'created' => created_at.to_datetime.rfc3339 }.to_json if created_at
    end
  end

  def stub_upload(content, digest, success: true)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:upload_blob)
      .with(repository.path, content, digest) { double(success?: success ) }
  end

  def expect_delete_tag_by_digest(digest)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:delete_repository_tag_by_digest)
      .with(repository.path, digest) { true }

    expect_any_instance_of(ContainerRegistry::Client)
      .not_to receive(:delete_repository_tag_by_name)
  end

  def expect_delete_tag_by_name(name)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:delete_repository_tag_by_name)
      .with(repository.path, name) { true }

    expect_any_instance_of(ContainerRegistry::Client)
      .not_to receive(:delete_repository_tag_by_digest)
  end
end
