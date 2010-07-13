class AddHostnameTemplateToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :hostname_template, :string
    add_index :servers, [ :hostname_template, :cluster_id ]
  end

  def self.down
    remove_column :servers, :hostname_template
  end
end
