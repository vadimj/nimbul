class CreateFirewallRules < ActiveRecord::Migration
  def self.up
    create_table :firewall_rules do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :type
      t.string :protocol
      t.string :from_port
      t.string :to_port
      t.string :ip_range

      t.timestamps
    end
    add_index :firewall_rules, :name
    add_index :firewall_rules, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :firewall_rules
  end
end
