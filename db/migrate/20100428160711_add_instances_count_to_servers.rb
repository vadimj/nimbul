class AddInstancesCountToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :instances_count, :integer, :default => 0
    Server.reset_column_information
    Server.find(:all).each do |c|
      c.update_attribute :instances_count, c.instances.length
    end
  end

  def self.down
    remove_column :servers, :instances_count
  end
end
