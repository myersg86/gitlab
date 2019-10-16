# frozen_string_literal: true

require 'spec_helper'

describe Security::ProjectsController do
  let(:user) { create(:user) }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  describe 'GET #index' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        get :index
      end
    end
  end

  describe 'POST #create' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        post :create
      end
    end

    context 'with an authenticated user' do
      let(:projects) { create_list(:project, 2) }

      before do
        sign_in(user)

        projects.each do |project|
          project.add_developer(user)
        end
      end

      it 'adds projects to the dasboard' do
        post :create, params: { project_ids: projects.pluck(:id) }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to match_schema('dashboard/security/projects/create', dir: 'ee')
        expect(json_response['added']).to contain_exactly(*projects.pluck(:id))
        expect(json_response['duplicate']).to be_empty
        expect(json_response['invalid']).to be_empty

        user.reload
        expect(user.security_dashboard_projects).to contain_exactly(*projects.pluck(:id))
      end

      it 'only adds each project once' do
        post :create, params: { project_ids: [projects.first.id, projects.first.id] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to match_schema('dashboard/security/projects/create', dir: 'ee')
        expect(json_response['added']).to contain_exactly(projects.first.id)
        expect(json_response['duplicate']).to be_empty
        expect(json_response['invalid']).to be_empty

        user.reload
        expect(user.security_dashboard_projects).to eq([projects.first.id])
      end

      it 'does not add invalid project ids' do
        post :create, params: { project_ids: ['', -1, '-2'] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to match_schema('dashboard/security/projects/create', dir: 'ee')
        expect(json_response['added']).to be_empty
        expect(json_response['duplicate']).to be_empty
        expect(json_response['invalid']).to contain_exactly('', '-1', '-2')

        user.reload
        expect(user.security_dashboard_projects).to be_empty
      end

      it 'does not add projects that the current user cannot access' do
        no_access_project = create(:project)

        post :create, params: { project_ids: [no_access_project.id] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to match_schema('dashboard/security/projects/create', dir: 'ee')
        expect(json_response['added']).to be_empty
        expect(json_response['duplicate']).to be_empty
        expect(json_response['invalid']).to be_empty

        user.reload
        expect(user.security_dashboard_projects).to be_empty
      end
    end
  end

  describe 'DELETE #destroy' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        delete :destroy, params: { id: 1 }
      end
    end
  end
end
