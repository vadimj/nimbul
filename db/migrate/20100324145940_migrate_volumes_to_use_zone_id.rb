require 'pp'

class MigrateVolumesToUseZoneId < ActiveRecord::Migration
  def self.up
    zones = {}
    Zone.find(:all).each do |zone|
      hash = zone.provider_account_id.to_s + ':' + zone.name.to_s
      zones[hash] = zone
    end

    Volume.find(:all).each do |volume|
      hash = volume.provider_account_id.to_s + ':' + volume.availability_zone.to_s
      volume.update_attributes!({ :zone_id => zones[hash].id }) unless zones[hash].nil?
    end
  end

  def self.down
    Volume.find(:all).each do |volume|
      zone = Zone.find(volume.zone_id)
      volume.update_attributes!({ :availability_zone => zone.name }) unless zone.nil?
    end
  end
end
