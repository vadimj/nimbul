class MigrateKeymanagerAndSnapshotTypeNames < ActiveRecord::Migration
  MAPPINGS = {
    'Operations::Keymanager'         => 'Operations::SshKeys',
    'Operations::Keymanager::Add'    => 'Operations::SshKeys::Add',
    'Operations::Keymanager::Delete' => 'Operations::SshKeys::Delete',
    'Operations::Purgesnapshots'     => 'Operations::Snapshot::Purge',
    'Operations::Mysqlsnapshot'      => 'Operations::Snapshot::Mysql',
  }
  
  TABLES = {
    'operations'   => 'type',
    'server_tasks' => 'operation'
  }
  
  def self.up
    convert MAPPINGS
  end

  def self.down
    convert MAPPINGS.invert
  end
  
  def self.convert mappings
    TABLES.each do |table,column|
      puts "Converting Operation Names for #{table}.#{column}"
      mappings.each do |old_name,new_name|
        puts "   -> remapping '#{old_name}' -> '#{new_name}'"
        execute "UPDATE #{table} SET #{column} = '#{new_name}' WHERE #{column} = '#{old_name}'"
      end
    end
  end
end
