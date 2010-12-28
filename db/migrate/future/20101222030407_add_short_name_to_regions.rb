class AddShortNameToRegions < ActiveRecord::Migration
  def self.up
    add_column :regions, :short_name, :string
  end

  def self.down
    remove_column :regions, :short_name
  end
end
