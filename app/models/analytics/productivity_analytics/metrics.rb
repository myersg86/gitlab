# frozen_string_literal: true

class Analytics::ProductivityAnalytics::Metrics < ActiveRecord::Base
  belongs_to :merge_request
  # TODO: rename to pipeline_success_count since we don't count skipped\cancelled pipelines here.
  validates :pipelines_count, numericality: { greater_than_or_equal_to: 0 }
  validates :failed_pipelines_count, numericality: { greater_than_or_equal_to: 0 }
  validates :merged_at, presence: true

  def self.test_data
    [
      # {opened_at: '2019-11-05', merged_at: '2019-11-05', pipelines_count: 2, failed_pipelines_count: 0},
      # {opened_at: '2019-11-04', merged_at: '2019-11-05', pipelines_count: 1, failed_pipelines_count: 0},
      {opened_at: '2019-11-01', merged_at: '2019-11-04', pipelines_count: 1, failed_pipelines_count: 0},
      {opened_at: '2019-11-01', merged_at: '2019-11-04', pipelines_count: 2, failed_pipelines_count: 0},
      {opened_at: '2019-11-01', merged_at: '2019-11-01', pipelines_count: 1, failed_pipelines_count: 0},
      {opened_at: '2019-11-01', merged_at: '2019-11-04', pipelines_count: 1, failed_pipelines_count: 0},
      {opened_at: '2019-11-01', merged_at: '2019-11-04', pipelines_count: 2, failed_pipelines_count: 1},
      {opened_at: '2019-10-31', merged_at: '2019-11-04', pipelines_count: 2, failed_pipelines_count: 1},
      {opened_at: '2019-10-31', merged_at: '2019-11-05', pipelines_count: 5, failed_pipelines_count: 0},
      {opened_at: '2019-10-31', merged_at: '2019-11-04', pipelines_count: 3, failed_pipelines_count: 0},
      {opened_at: '2019-10-31', merged_at: '2019-11-05', pipelines_count: 3, failed_pipelines_count: 3},
      {opened_at: '2019-10-30', merged_at: '2019-11-05', pipelines_count: 1, failed_pipelines_count: 1},
      {opened_at: '2019-10-30', merged_at: '2019-10-30', pipelines_count: 1, failed_pipelines_count: 1},
      {opened_at: '2019-10-30', merged_at: '2019-10-30', pipelines_count: 0, failed_pipelines_count: 1},
      {opened_at: '2019-10-30', merged_at: '2019-11-05', pipelines_count: 4, failed_pipelines_count: 7},
      {opened_at: '2019-10-30', merged_at: '2019-10-31', pipelines_count: 1, failed_pipelines_count: 1},
      {opened_at: '2019-10-30', merged_at: '2019-11-05', pipelines_count: 7, failed_pipelines_count: 8},
      {opened_at: '2019-10-29', merged_at: '2019-11-04', pipelines_count: 2, failed_pipelines_count: 8},
      {opened_at: '2019-10-29', merged_at: '2019-10-31', pipelines_count: 2, failed_pipelines_count: 3},
      {opened_at: '2019-10-29', merged_at: '2019-10-30', pipelines_count: 2, failed_pipelines_count: 1}
    ]
  end

  def self.fill_test_data_for(project)
    project.merge_requests.merged.each.with_index do |mr, i|
      create!(test_data[i].merge(merge_request: mr))
    end
  end

  def self.create_from!(mr)
    create!(
      merge_request: mr,
      pipelines_count: mr.all_pipelines.size,
      failed_pipelines_count: mr.all_pipelines.failed.size,
      merged_at: mr.merged_at,
      opened_at: mr.created_at
    )
  end

  def pipeline_failure_percentage
    return 0 unless total_completed_pipelines.positive?

    100 * failed_pipelines_count.to_f / total_completed_pipelines
  end

  def total_completed_pipelines
    @total_completed_pipelines ||= pipelines_count + failed_pipelines_count
  end

  def pipelines_per_day
    total_completed_pipelines.to_f / mr_open_period
  end

  def mr_open_period
    [((merged_at - opened_at) / 86400).round, 1].max # exclude non-work days?
  end
end
