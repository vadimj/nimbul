class RemoveDuplicateZones < ActiveRecord::Migration
  TABLES = [
    :instances,
    :resource_bundles,
    :cloud_resources,
    :instance_allocation_records
  ]

  def self.up
    seen = []
    zones = {}

    # find duplicate zones
    Zone.find(:all).each do |z|
      azs = Zone.find_all_by_provider_account_id_and_name(z.provider_account_id, z.name)
      az_ids = azs.collect{ |az| az.id unless (az.id == z.id or seen.include?(az.id))}.compact
      zones[z.id] = az_ids unless az_ids.empty?
      seen += az_ids
    end

    # re-assign resources for duplicate zones
    zones.each do |z, dup_zs|
      dup_zs.each do |dz|
        TABLES.each do |t|
          execute("UPDATE #{t.to_s} SET zone_id=#{z.id} WHERE zone_id=#{dz.id}")
        end
      end
    end

    # remove all zones without resources
    Zone.find(:all).each do |z|
      z.destroy unless z.has_resources?
    end
  end

  def self.down
  end
end
