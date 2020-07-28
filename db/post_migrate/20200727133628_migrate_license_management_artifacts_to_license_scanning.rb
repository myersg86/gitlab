# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateLicenseManagementArtifactsToLicenseScanning < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_job_artifacts'

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    scope :original_reports, -> { select("MIN(id) as id").group(:job_id) }
    scope :license_compliance, -> { where(file_type: [10, 101]) }
  end

  # We're updating file_type of ci artifacts from license_management to license_scanning
  # But before that we need to delete "rogue" artifacts for CI builds that have associated with them
  # both license_scanning and license_management artifacts. It's an edge case and usually, we don't have
  # such builds in the database.
def up
    return unless Gitlab.ee?
    JobArtifact.license_compliance.where.not(id: JobArtifact.license_compliance.original_reports).delete_all
    JobArtifact.where(file_type: 10).each_batch do |relation|
      relation.update_all(file_type: 101)
    end
  end

  def down
    # no-op
    # we're deleting duplicating artifacts and updating file_type for license_management artifacts
  end
end
