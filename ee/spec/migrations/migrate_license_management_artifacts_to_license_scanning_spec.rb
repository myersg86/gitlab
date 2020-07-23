# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200723133628_migrate_license_management_artifacts_to_license_scanning.rb')

RSpec.describe MigrateLicenseManagementArtifactsToLicenseScanning, :migration, :sidekiq do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:builds) { table(:ci_builds) }
  let(:license_management_type) { 10 }
  let(:license_scanning_type) { 101 }

  before do
    namespaces.create!(id: 1, name: 'tanuki', path: 'tanuki')
    projects.create!(id: 42, name: 'tanuki', path: 'tanuki', namespace_id: 1)
    builds.create!(id: 1)
    builds.create!(id: 2)
    builds.create!(id: 3)
    job_artifacts.create!(project_id: 42, job_id: 1, file_type: 10)
    job_artifacts.create!(project_id: 42, job_id: 2, file_type: 9)
    job_artifacts.create!(project_id: 42, job_id: 2, file_type: 10)
  end

  context 'with two types of the report' do
    before do
      job_artifacts.create!(project_id: 42, job_id: 1, file_type: 101)
    end

    it 'leaves only one artifact' do
      migrate!

      expect(job_artifacts.where(file_type: 10).count).to eq 0
      expect(job_artifacts.where(file_type: 101).count).to eq 2
      expect(job_artifacts.where(file_type: 9).count).to eq 1
    end
  end

  context 'with only license_management report' do
    it 'change' do
      migrate!

      expect(job_artifacts.where(file_type: 10).count).to eq 0
      expect(job_artifacts.where(file_type: 101).count).to eq 2
      expect(job_artifacts.where(file_type: 9).count).to eq 1
    end
  end
end
