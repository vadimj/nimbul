class RenameZoneToAvailabilityZoneForServers < ActiveRecord::Migration
    def self.up
        rename_column :servers, :zone, :availability_zone
    end
    def self.down
        rename_column :servers, :availability_zone, zone
    end
end
