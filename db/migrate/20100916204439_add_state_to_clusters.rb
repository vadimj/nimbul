class AddStateToClusters < ActiveRecord::Migration
  def self.up
    add_column :clusters, :state, :string, :default => :active
    add_index :clusters, :state
  end

  def self.down
    remove_column :clusters, :state
  end
end
