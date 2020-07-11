# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateLicenseManagementArtifactsToLicenseScanning < ActiveRecord::Migration[6.0]
  # include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    has_many :job_artifacts, class_name: 'Ci::JobArtifact', foreign_key: :job_id, inverse_of: :job

    scope :with_both_artifacts, -> {  }
  end

  class JobArtifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    scope :with_both_artifacts, -> { where(file_type: [10, 101]).group(:job_id).having('count(*) > 1') }
  end

  def up

    JobArtifact.with_both_artifacts.each do |pair|
      pair.last.destroy
    end
    JobArtifact.where(file_type: 101).update(file_type: 10)
  end

  def down; end
end
