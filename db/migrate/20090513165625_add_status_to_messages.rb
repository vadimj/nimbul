class AddStatusToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :status, :string, :default => 'unknown'
    add_index :messages, [ :provider_account_id, :status ]
  end

  def self.down
    remove_column :messages, :status
  end
end
