class AdjustIndexAccountIdNameOnCloudResources < ActiveRecord::Migration
    def self.up
        remove_index :cloud_resources, [ :provider_account_id, :name ]
    end

    def self.down
        add_index :cloud_resources, [ :provider_account_id, :name, :type ], :unique => true
    end
end
