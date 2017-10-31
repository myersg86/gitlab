class Geo::SchedulerWorker < Geo::TrackingBase
  def self.current
    Geo::SchedulerWorker.last
  end

  def self.ensure_schedule_workers!
    return unless self.connected_to_db?

    Geo::SchedulerWorker.current || Geo::SchedulerWorker.create
  end

  def self.connected_to_db?
    db_connection = Geo::SchedulerWorker.connection.active? rescue false

    db_connection &&
      Geo::SchedulerWorker.connection.table_exists?(Geo::SchedulerWorker.table_name)
  rescue ActiveRecord::NoDatabaseError
    false
  end
end
