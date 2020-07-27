# frozen_string_literal: true

class UpdateDefaultsForScaArtifacts < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_default :plan_limits, :ci_max_artifact_size_dependency_scanning, 350
    change_column_default :plan_limits, :ci_max_artifact_size_container_scanning, 150
    change_column_default :plan_limits, :ci_max_artifact_size_license_scanning, 100
  end

  def down
    change_column_default :plan_limits, :ci_max_artifact_size_dependency_scanning, 0
    change_column_default :plan_limits, :ci_max_artifact_size_container_scanning, 0
    change_column_default :plan_limits, :ci_max_artifact_size_license_scanning, 0
  end
end
