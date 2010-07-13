class AddDnsAssignableToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :dns_assignable, :boolean, :default => 1
  end

  def self.down
    remove_column :instances, :dns_assignable
  end
end
