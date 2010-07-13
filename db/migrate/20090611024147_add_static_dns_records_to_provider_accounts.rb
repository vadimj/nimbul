class AddStaticDnsRecordsToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :static_dns_records, :text, :default => ''
  end

  def self.down
    remove_column :provider_accounts, :static_dns_records
  end
end
