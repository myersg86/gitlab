# frozen_string_literal: true

require 'airborne'
require 'securerandom'

module QA
  context 'Enablement:Search' do
    describe 'When using elasticsearch API to search for a known blob', :orchestrated, :elasticsearch, :requires_admin do
      let(:project_file_content) { "elasticsearch: #{SecureRandom.hex(8)}" }
      let(:non_member_user) { Resource::User.fabricate_or_use('non_member_user', 'non_member_user_password') }
      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:non_member_api_client) { Runtime::API::Client.new(user: non_member_user) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "api-es-#{SecureRandom.hex(8)}"
        end
      end

      let(:elasticsearch_original_state_on?) { Runtime::Search.elasticsearch_on?(api_client) }

      before do
        unless elasticsearch_original_state_on?
          QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api!
          sleep(60)
          # wait for the change to propagate before inserting records or else
          # Gitlab::CurrentSettings.elasticsearch_indexing and
          # Elastic::ApplicationVersionedSearch::searchable? will be false
          # this sleep can be removed after we're able to query logs via the API
          # as per this issue https://gitlab.com/gitlab-org/quality/team-tasks/issues/395
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.add_files([
            { file_path: 'README.md', content: project_file_content }
          ])
        end
      end

      after do
        if !elasticsearch_original_state_on? && !api_client.nil?
          Runtime::Search.disable_elasticsearch(api_client)
        end
      end

      it 'searches public project and finds a blob as an non-member user' do
        successful_search(non_member_api_client)
      end

      describe 'When searching a private repository' do
        before do
          project.set_visibility(:private)
        end

        it 'finds a blob as an authorized user' do
          successful_search(api_client)
        end

        it 'does not find a blob as an non-member user' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 10, sleep_interval: 3) do
            get Runtime::Search.create_search_request(non_member_api_client, 'blobs', project_file_content).url
            expect_status(QA::Support::Api::HTTP_STATUS_OK)
            expect(json_body).to be_empty
          end
        end
      end

      private

      def successful_search(api_client)
        QA::Support::Retrier.retry_on_exception(max_attempts: 10, sleep_interval: 3) do
          get Runtime::Search.create_search_request(api_client, 'blobs', project_file_content).url
          expect_status(QA::Support::Api::HTTP_STATUS_OK)

          raise 'Empty search result returned' if json_body.empty?

          expect(json_body[0][:data]).to match(project_file_content)
          expect(json_body[0][:project_id]).to equal(project.id)
        end
      end
    end
  end
end
