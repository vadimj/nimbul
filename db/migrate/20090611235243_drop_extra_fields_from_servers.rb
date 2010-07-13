class DropExtraFieldsFromServers < ActiveRecord::Migration
  def self.up
    remove_column :servers, :provider_account_id
    remove_column :servers, :image_id
    remove_column :servers, :type
    remove_column :servers, :startup_script
  end

  def self.down
    add_column :servers, :provider_account_id, :integer
    add_column :servers, :image_id, :string
    add_column :servers, :type, :string
    add_column :servers, :startup_script, :text
  end
end
