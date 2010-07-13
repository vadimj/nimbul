class CreateServerTasks < ActiveRecord::Migration
  def self.up
    create_table :server_tasks do |t|
      t.integer :server_id
      t.string :name
      t.string :description
      t.string :operation
      t.datetime :active_from
      t.datetime :active_to
      t.boolean :is_active
      t.boolean :is_scheduled
      t.boolean :is_repeatable
      t.integer :run_every_value
      t.string :run_every_units
      t.datetime :run_at
      t.integer :run_in_value
      t.string :run_in_units
      t.string :run_cron
      t.integer :timeout
      t.string  :state
      t.text    :state_text

      t.timestamps
    end
  end

  def self.down
    drop_table :server_tasks
  end
end
