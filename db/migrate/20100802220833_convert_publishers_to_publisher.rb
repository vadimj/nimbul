class ConvertPublishersToPublisher < ActiveRecord::Migration
  TABLES = {
    'publishers' => 'type',
  }
  
  SEARCH  = 'Publishers::'
  REPLACE = 'Publisher::'

  def self.up
    convert SEARCH, REPLACE
  end

  def self.down
    convert REPLACE, SEARCH 
  end
  
  def self.convert search, replace
    TABLES.each do |table,column|
      puts "Converting Publisher Names for #{table}.#{column}"
      execute "UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{search}', '#{replace}')"
    end
  end
end
