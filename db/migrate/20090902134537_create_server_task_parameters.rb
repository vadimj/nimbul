class CreateServerTaskParameters < ActiveRecord::Migration
  def self.up
    create_table :server_task_parameters do |t|
      t.integer :server_task_id
      t.string :type
      t.string :name
      t.string :description
      t.string :value
      t.string :control_type

      t.timestamps
    end
  end

  def self.down
    drop_table :server_task_parameters
  end
end
