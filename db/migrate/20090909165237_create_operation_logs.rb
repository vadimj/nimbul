class CreateOperationLogs < ActiveRecord::Migration
  def self.up
    create_table :operation_logs do |t|
      t.integer :operation_id
      t.string :step_name
      t.boolean :is_success
      t.string :result_code
      t.text :result_message

      t.timestamps
    end
  end

  def self.down
    drop_table :operation_logs
  end
end
