class CreateAuditLogs < ActiveRecord::Migration
  def self.up
    create_table :audit_logs do |t|
      t.string :provider_account_name
      t.integer :provider_account_id
      t.string :cluster_name
      t.integer :cluster_id
      t.integer :auditable_id
      t.string :auditable_type
      t.string :auditable_name
      t.string :author_login
      t.integer :author_id
      t.string :summary
      t.text :changes

      t.timestamps
    end
    add_index :audit_logs, :provider_account_name
    add_index :audit_logs, :provider_account_id
    add_index :audit_logs, :cluster_name
    add_index :audit_logs, :cluster_id
    add_index :audit_logs, [ :auditable_id, :auditable_type ]
    add_index :audit_logs, :auditable_name
    add_index :audit_logs, :author_login
    add_index :audit_logs, :author_id
    add_index :audit_logs, :summary
  end

  def self.down
    drop_table :audit_logs
  end
end
