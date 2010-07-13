class AddServerNameAndServerIdToAuditLogs < ActiveRecord::Migration
  def self.up
    add_column :audit_logs, :server_name, :string
    add_column :audit_logs, :server_id, :integer
    add_index :audit_logs, :server_name
    add_index :audit_logs, :server_id
  end

  def self.down
    remove_column :audit_logs, :server_id
    remove_column :audit_logs, :server_name
  end
end
