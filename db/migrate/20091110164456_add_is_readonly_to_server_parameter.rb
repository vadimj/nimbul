class AddIsReadonlyToServerParameter < ActiveRecord::Migration
  def self.up
    add_column :server_parameters, :is_readonly, :boolean, :default => 0
  end

  def self.down
    remove_column :server_parameters, :is_readonly
  end
end
