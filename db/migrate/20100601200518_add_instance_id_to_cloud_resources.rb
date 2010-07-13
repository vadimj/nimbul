class AddInstanceIdToCloudResources < ActiveRecord::Migration
    def self.up
        add_column :cloud_resources, :instance_id, :integer
        add_column :cloud_resources, :cloud_instance_id, :string
        add_index :cloud_resources, [ :provider_account_id, :instance_id ]
        add_index :cloud_resources, [ :provider_account_id, :cloud_instance_id ], :name => 'index_crs_on_paid_and_ciid'
    end

    def self.down
        remove_column :cloud_resources, :instance_id
        remove_column :cloud_resources, :cloud_instance_id
    end
end
