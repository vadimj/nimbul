class MoveOverridableFromServiceProvidersToServiceOverrides < ActiveRecord::Migration
  def self.up
    add_column :service_overrides, :overridable, :boolean, :default => true
    remove_column :service_providers, :overridable
  end

  def self.down
    remove_column :service_overrides, :overridable
    add_column :service_providers, :overridable, :boolean, :default => true
  end
end
