class CreateAvailabilityZones < ActiveRecord::Migration
  def self.up
    create_table :availability_zones do |t|
      t.primary_key :id
      t.integer :provider_account_id
      t.string :name
      t.enum :state, :limit => [ :unavailable, :available ], :default => :available
      t.string :region

      t.timestamps
    end
  end

  def self.down
    drop_table :availability_zones
  end
end
