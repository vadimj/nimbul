class AddInQueueAndOutQueueToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :in_queue, :string
    add_column :provider_accounts, :out_queue, :string
  end

  def self.down
    remove_column :provider_accounts, :in_queue
    remove_column :provider_accounts, :out_queue
  end
end
