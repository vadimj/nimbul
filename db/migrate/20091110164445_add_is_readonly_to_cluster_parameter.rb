class AddIsReadonlyToClusterParameter < ActiveRecord::Migration
  def self.up
    add_column :cluster_parameters, :is_readonly, :boolean, :default => 0
  end

  def self.down
    remove_column :cluster_parameters, :is_readonly
  end
end
