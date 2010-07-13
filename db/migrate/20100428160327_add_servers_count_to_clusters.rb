class AddServersCountToClusters < ActiveRecord::Migration
  def self.up
    add_column :clusters, :servers_count, :integer, :default => 0
    Cluster.reset_column_information
    Cluster.find(:all).each do |c|
      c.update_attribute :servers_count, c.servers.length
    end
  end

  def self.down
    remove_column :clusters, :servers_count
  end
end
