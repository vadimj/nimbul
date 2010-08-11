class AddTypeParentTypeIdTaskableTypeIdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :parent_type, :string
    add_column :tasks, :parent_id, :integer
    add_column :tasks, :taskable_type, :string, :default => 'Server'
    rename_column :tasks, :server_id, :taskable_id
  end

  def self.down
    rename_column :tasks, :taskable_id, :server_id
    remove_column :tasks, :taskable_type
    remove_column :tasks, :parent_id
    remove_column :tasks, :parent_type
  end
end
