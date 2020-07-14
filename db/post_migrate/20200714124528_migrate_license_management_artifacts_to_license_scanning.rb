# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateLicenseManagementArtifactsToLicenseScanning < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    scope :duplicates, -> { select("MIN(id) as id").group(:job_id).map(&:id) }
    scope :license_compliance, -> { where(file_type: [10, 101]) }
  end

  def up
    JobArtifact.license_compliance.where.not(id: JobArtifact.license_compliance.duplicates).delete_all
    JobArtifact.where(file_type: 10).update(file_type: 101)
  end

  def down; end
end
