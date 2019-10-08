# frozen_string_literal: true

require 'spec_helper'

describe 'AWS EKS Cluster', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:provision_config) { instance_double(Gitlab::Kubernetes::Provisioners::Aws, account_id: '123456789012') }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
    allow(Gitlab::Kubernetes::Provisioners::Aws).to receive(:new).and_return(provision_config)
  end

  context 'when user does not have a cluster and visits cluster index page' do
    let(:project_id) { 'test-project-1234' }

    before do
      visit project_clusters_path(project)

      click_link 'Add Kubernetes cluster'
    end

    context 'when user creates a cluster on AWS EKS' do
      before do
        click_link 'Amazon EKS'
      end

      it 'user sees a form to create an EKS cluster' do
        expect(page).to have_selector(:css, '.js-create-eks-cluster')
      end
    end
  end
end
