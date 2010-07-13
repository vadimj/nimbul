class CreateFirewallRulesSecurityGroupsTable < ActiveRecord::Migration
  def self.up
    create_table :firewall_rules_security_groups, :id => false do |t|
        t.integer :firewall_rule_id, :security_group_id
    end
    add_index :firewall_rules_security_groups, :firewall_rule_id
    add_index :firewall_rules_security_groups, :security_group_id
  end

  def self.down
    drop_table :firewall_rules_security_groups 
  end
end
