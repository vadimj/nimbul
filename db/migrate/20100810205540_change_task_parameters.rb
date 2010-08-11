class ChangeTaskParameters < ActiveRecord::Migration
  def self.up
    drop_table :task_parameters
    create_table :task_parameters do |t|
      t.integer :task_id
      t.string :name
      t.string :custom_value
      t.string :value_provider_type
      t.integer :value_provider_id

      t.timestamps
    end
    add_index :task_parameters, :task_id
    add_index :task_parameters, [ :value_provider_type, :value_provider_id ], :name => :index_task_parameters_on_vp_type_and_vp_id
  end

  def self.down
    drop_table :task_parameters
    create_table :task_parameters do |t|
      t.integer :task_id
      t.string :type
      t.string :name
      t.string :description
      t.string :value
      t.string :control_type

      t.timestamps
    end
  end
end