class AddGroupInfoToFirewallRules < ActiveRecord::Migration
  def self.up
    add_column :firewall_rules, :group_user_id, :string
    add_column :firewall_rules, :group_name, :string
    add_index :firewall_rules, [ :provider_account_id, :protocol, :from_port, :to_port, :ip_range ], :unique => true, :name => :index_ip_range_on_firewall_rules
    add_index :firewall_rules, [ :provider_account_id, :group_user_id, :group_name ], :unique => true, :name => :index_group_on_firewall_rules
  end

  def self.down
    remove_column :firewall_rules, :group_user_id
    remove_column :firewall_rules, :group_name
    remove_index :firewall_rules, :name => :index_ip_range_on_firewall_rules
    remove_index :firewall_rules, :name => :index_group_on_firewall_rules
  end
end
