class AddCurrentBootstrapAttemptAndHasKeyToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :bootstrap_attempt, :integer, :default => 0
    add_column :instances, :has_key, :boolean, :default => false
  end

  def self.down
    remove_column :instances, :has_key
    remove_column :instances, :bootstrap_attempt
  end
end
