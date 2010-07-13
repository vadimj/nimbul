class AddDescriptionAndNameToServiceProviders < ActiveRecord::Migration
  def self.up
    add_column :service_providers, :name, :string, :limit => 75
    add_column :service_providers, :description, :text
  end

  def self.down
    remove_column :service_providers, :name
    remove_column :service_providers, :description
  end
end
