class AddStateToResources < ActiveRecord::Migration
  def self.up
	add_column :key_pairs, :state, :string
	add_column :security_groups, :state, :string
	add_column :addresses, :state, :string
	add_column :volumes, :state, :string
  end

  def self.down
	remove_column :key_pairs, :state
	remove_column :security_groups, :state
	remove_column :addresses, :state
	remove_column :volumes, :state
  end
end
