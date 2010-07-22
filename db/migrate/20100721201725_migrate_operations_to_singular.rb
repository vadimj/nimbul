class MigrateOperationsToSingular < ActiveRecord::Migration
  TABLES = {
    'operations'   => 'type',
    'server_tasks' => 'operation'
  }
  
  SEARCH  = 'Operations::'
  REPLACE = 'Operation::'

  def self.up
    convert SEARCH, REPLACE
  end

  def self.down
    convert REPLACE, SEARCH 
  end
  
  def self.convert search, replace
    TABLES.each do |table,column|
      puts "Converting Operation Names for #{table}.#{column}"
      execute "UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{search}', '#{replace}')"
    end
  end
end
