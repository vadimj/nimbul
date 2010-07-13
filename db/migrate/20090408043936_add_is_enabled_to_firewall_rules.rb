class AddIsEnabledToFirewallRules < ActiveRecord::Migration
  def self.up
    add_column :firewall_rules, :is_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :firewall_rules, :is_enabled
  end
end
