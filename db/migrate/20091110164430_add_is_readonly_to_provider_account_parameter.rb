class AddIsReadonlyToProviderAccountParameter < ActiveRecord::Migration
  def self.up
    add_column :provider_account_parameters, :is_readonly, :boolean, :default => 0
  end

  def self.down
    remove_column :provider_account_parameters, :is_readonly
  end
end
