class RenameServerTasksToTasks < ActiveRecord::Migration
  def self.up
    rename_table :server_task_parameters, :task_parameters
    rename_column :task_parameters, :server_task_id, :task_id
    rename_column :operations, :server_task_id, :task_id
    rename_table :server_tasks, :tasks
  end

  def self.down
    rename_table :task_parameters, :server_task_parameters
    rename_column :server_task_parameters, :task_id, :server_task_id
    rename_column :operations, :task_id, :server_task_id
    rename_table :tasks, :server_tasks
  end
end
