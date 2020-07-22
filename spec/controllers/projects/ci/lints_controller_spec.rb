# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::LintsController do
  include StubRequests

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'with enough privileges' do
      before do
        project.add_developer(user)

        get :show, params: { namespace_id: project.namespace, project_id: project }
      end

      it { expect(response).to be_successful }

      it 'renders show page' do
        expect(response).to render_template :show
      end

      it 'retrieves project' do
        expect(assigns(:project)).to eq(project)
      end
    end

    context 'without enough privileges' do
      before do
        project.add_guest(user)

        get :show, params: { namespace_id: project.namespace, project_id: project }
      end

      it 'responds with 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:params) { { namespace_id: project.namespace, project_id: project, content: content, format: format } }

    RSpec.shared_context 'valid config' do
      let(:remote_file_path) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

      let(:remote_file_content) do
        <<~HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      end

      let(:content) do
        <<~HEREDOC
        include:
          - #{remote_file_path}

        rubocop:
          script:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        stub_full_request(remote_file_path).to_return(body: remote_file_content)

        post :create, params: params
      end
    end

    RSpec.shared_context 'invalid config' do
      let(:content) do
        <<~HEREDOC
        rubocop:
          scriptt:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        post :create, params: params
      end
    end

    context 'when format is html' do
      let(:format) { 'html' }

      context 'with linting privileges' do
        before do
          project.add_developer(user)
        end

        context 'with a valid gitlab-ci.yml' do
          include_context 'valid config'

          it { expect(response).to be_successful }

          it 'render show page' do
            expect(response).to render_template :show
          end

          it 'retrieves project' do
            expect(assigns(:project)).to eq(project)
          end
        end

        context 'with an invalid gitlab-ci.yml' do
          include_context 'invalid config'

          it 'assigns errors' do
            expect(assigns[:errors]).to eq(['root config contains unknown keys: rubocop'])
          end
        end
      end

      context 'without linting privileges' do
        before do
          project.add_guest(user)
        end

        include_context 'valid config'

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when requested format is json' do
      let(:body) { Gitlab::Json.parse(response.body) }
      let(:format) { 'json' }

      context 'with linting privileges' do
        before do
          project.add_developer(user)
        end

        context 'with a valid gitlab-ci.yml' do
          include_context 'valid config'

          it { expect(response).to be_successful }

          it 'returns json content' do
            expect(response.content_type).to eq "application/json"
          end

          it 'returns data for valid config' do
            expect(body['valid']).to eq(true)
            expect(body['errors']).to eq([])
            expect(body['config']['builds']).not_to be_empty
          end
        end

        context 'with an invalid gitlab-ci.yml' do
          include_context 'invalid config'

          it { expect(response).to be_successful }

          it 'returns json content' do
            expect(response.content_type).to eq "application/json"
          end

          it 'returns data for invalid config' do
            expect(body['valid']).to eq(false)
            expect(body['errors']).to eq(['root config contains unknown keys: rubocop'])
            expect(body['config']).to eq(nil)
          end
        end
      end

      context 'without linting privileges' do
        before do
          project.add_guest(user)
        end

        include_context 'valid config'

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
