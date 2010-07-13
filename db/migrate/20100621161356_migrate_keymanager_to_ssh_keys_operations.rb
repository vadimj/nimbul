class MigrateKeymanagerToSshKeysOperations < ActiveRecord::Migration
    def self.up
        execute "update operations set type='Operations::SshKeys::Add' where type='Operations::Keymanager::Add'"
        execute "update operations set type='Operations::SshKeys::Delete' where type='Operations::Keymanager::Delete'"
    end

    def self.down
        raise ActiveRecord::IrreversibleMigration, "Can't reliably convert new SshKeys operations to old Keymanager operations"
    end
end
