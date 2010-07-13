class RenameAvailabilityZonesToZones < ActiveRecord::Migration
  def self.up
    rename_table :auto_scaling_groups_availability_zones, :auto_scaling_groups_zones
    rename_table :availability_zones_load_balancers, :load_balancers_zones
    rename_table :availability_zones, :zones	
    rename_column :auto_scaling_groups_zones, :availability_zone_id, :zone_id
    rename_column :load_balancers_zones, :availability_zone_id, :zone_id
    remove_column :zones, :region
    add_column :zones, :region_id, :integer
    add_index :zones, [ :region_id ]

    accounts = ProviderAccount.find(:all)

    zones = ActiveRecord::Base.connection.execute('SELECT DISTINCT zone FROM servers WHERE zone IS NOT NULL AND zone != ""')
    zones.all_hashes.collect{|z|z.to_a.flatten[1]}.each do |zone|
      accounts.each do |account|
        Zone.create({:provider_account_id => account.id, :name => zone})
      end
    end
  end

  def self.down
    remove_column :zones, :region_id
    add_column :zones, :region, :string
    rename_column :auto_scaling_groups_zones, :zone_id, :availability_zone_id
    rename_column :load_balancers_zones, :zone_id, :availability_zone_id
    rename_table :zones, :availability_zones
    rename_table :auto_scaling_groups_zones, :auto_scaling_groups_availability_zones
    rename_table :load_balancers_zones, :availability_zones_load_balancers
  end
end
