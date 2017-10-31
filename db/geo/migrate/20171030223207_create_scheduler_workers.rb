class CreateSchedulerWorkers < ActiveRecord::Migration
  def change
    create_table :scheduler_workers do |t|
      t.text :file_download_scheduler_jid
      t.text :repository_scheduler_jid
    end
  end
end
