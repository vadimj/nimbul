class AddOverridableToServiceProvider < ActiveRecord::Migration
  def self.up
    add_column :service_providers, :overridable, :boolean, :default => true
  end

  def self.down
    remove_column :service_providers, :overridable
  end
end
