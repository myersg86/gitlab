class GeoRepositorySyncWorker < Geo::BaseSchedulerWorker
  LEASE_KEY = 'geo_repository_sync_worker'.freeze
  LEASE_TIMEOUT = 10.minutes
  DB_RETRIEVE_BATCH_SIZE = 1000
  MAX_CAPACITY = 25
  RUN_TIME = 60.minutes.to_i

  BACKOFF_DELAY = 5.minutes

  private

  def lease_key
    LEASE_KEY
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def db_retrieve_batch_size
    DB_RETRIEVE_BATCH_SIZE
  end

  def max_capacity
    MAX_CAPACITY
  end

  def run_time
    RUN_TIME
  end

  def schedule_jobs
    num_to_schedule = [MAX_CAPACITY - scheduled_job_ids.size, @pending_resources.size].min

    return unless resources_remain?

    num_to_schedule.times do
      project_id = @pending_resources.shift
      job_id = Geo::ProjectSyncWorker.perform_in(BACKOFF_DELAY, project_id, Time.now)

      @scheduled_jobs << { id: project_id, job_id: job_id } if job_id
    end
  end

  def load_pending_resources
    project_ids_not_synced = find_project_ids_not_synced
    project_ids_updated_recently = find_project_ids_updated_recently

    @pending_resources = interleave(project_ids_not_synced, project_ids_updated_recently)
  end

  def find_project_ids_not_synced
    Project.where.not(id: Geo::ProjectRegistry.synced.pluck(:project_id))
           .order(last_repository_updated_at: :desc)
           .limit(DB_RETRIEVE_BATCH_SIZE)
           .pluck(:id)
  end

  def find_project_ids_updated_recently
    Geo::ProjectRegistry.dirty
                        .order(Gitlab::Database.nulls_first_order(:last_repository_synced_at, :desc))
                        .limit(DB_RETRIEVE_BATCH_SIZE)
                        .pluck(:project_id)
  end
end
