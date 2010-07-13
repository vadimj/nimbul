class PerformanceTweakingIndexingPhase1 < ActiveRecord::Migration
  def self.up
	add_index :firewall_rules, :provider_account_id
	add_index :instances, :provider_account_id
	add_index :instances, :state
	add_index :volumes, :provider_account_id
	add_index :volumes, :snapshot_id
	add_index :operations, :state
	add_index :server_images, :provider_account_id 
  end

  def self.down
	remove_index :firewall_rules, :provider_account_id
	remove_index :instances, :provider_account_id
	remove_index :instances, :state
	remove_index :volumes, :provider_account_id
	remove_index :volumes, :snapshot_id
	remove_index :operations, :state
	remove_index :server_images, :provider_account_id 
  end
end
