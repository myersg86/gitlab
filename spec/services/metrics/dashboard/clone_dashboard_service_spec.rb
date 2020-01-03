# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::CloneDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:environment) { create(:environment, project: project) }

  describe '#execute' do
    subject(:service_call) { described_class.new(project, user, params).execute }

    let(:commit_message) { 'test' }
    let(:branch) { "#{Time.current.to_i}_dashboard_new_branch" }
    let(:dashboard) { 'config/prometheus/common_metrics.yml' }
    let(:file_name) { 'custom_dashboard.yml' }
    let(:params) do
      {
        dashboard: dashboard,
        file_name: file_name,
        commit_message: commit_message,
        branch: branch
      }
    end

    context 'wrong source dashboard file' do
      let(:dashboard) { 'config/prometheus/common_metrics_123.yml' }

      it_behaves_like 'misconfigured dashboard service response', :not_found, 'Not found'
    end

    context 'path traversal attack attempt' do
      let(:dashboard) { 'config/prometheus/../database.yml' }

      it_behaves_like 'misconfigured dashboard service response', :not_found, 'Not found'
    end

    context 'wrong target file extension' do
      let(:file_name) { 'custom_dashboard.txt' }

      it_behaves_like 'misconfigured dashboard service response', :bad_request, 'File name should have .yml extension'
    end

    context 'user does not have push right to repository' do
      it_behaves_like 'misconfigured dashboard service response', :forbidden, %q(You can't commit to this project)
    end

    context 'with rights to push to the repository' do
      before do
        project.add_maintainer(user)
      end

      context 'valid parameters' do
        it 'delegates commit creation to Files::CreateService', :aggregate_failures do
          dashboard_attrs = {
            commit_message: commit_message,
            branch_name: branch,
            start_branch: 'master',
            encoding: 'text',
            file_path: '.gitlab/dashboards/custom_dashboard.yml',
            file_content: File.read(dashboard)
          }

          service_instance = instance_double(::Files::CreateService)
          expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
          expect(service_instance).to receive(:execute).and_return(status: :success)

          service_call
        end

        context 'selected branch already exists' do
          it 'pass correct params to Files::CreateService', :aggregate_failures do
            project.repository.add_branch(user, branch, 'master')

            dashboard_attrs = {
              commit_message: commit_message,
              branch_name: branch,
              start_branch: branch,
              encoding: 'text',
              file_path: '.gitlab/dashboards/custom_dashboard.yml',
              file_content: File.read(dashboard)
            }

            service_instance = instance_double(::Files::CreateService)
            expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
            expect(service_instance).to receive(:execute).and_return(status: :success)

            service_call
          end
        end

        context 'missing commit message' do
          before do
            params.delete(:commit_message)
          end

          it 'use default commit message' do
            dashboard_attrs = {
              commit_message: 'Create custom dashboard custom_dashboard.yml',
              branch_name: branch,
              start_branch: 'master',
              encoding: 'text',
              file_path: ".gitlab/dashboards/custom_dashboard.yml",
              file_content: File.read('config/prometheus/common_metrics.yml')
            }

            service_instance = instance_double(::Files::CreateService)
            expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
            expect(service_instance).to receive(:execute).and_return(status: :success)

            service_call
          end
        end

        it 'extends dashboard template path to absolute url' do
          allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :success }))

          expect(File).to receive(:read).with(Rails.root.join('config/prometheus/common_metrics.yml')).and_return('')

          service_call
        end

        context 'Files::CreateService success' do
          it 'clears dashboards cache' do
            allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :success }))

            expect(project.repository).to receive(:refresh_method_caches).with([:metrics_dashboard])

            service_call
          end

          it 'returns success' do
            result = service_call
            expect(result[:status]).to be :success
          end
        end

        context 'Files::CreateService fails' do
          it 'does NOT clear dashboards cache' do
            allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :error }))

            expect(project.repository).not_to receive(:refresh_method_caches)

            service_call
          end

          it 'returns error' do
            allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :error }))

            result = service_call
            expect(result[:status]).to be :error
          end
        end
      end
    end
  end
end
