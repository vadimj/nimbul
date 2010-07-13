require 'pp'

class MigrateInstancesToUseZoneId < ActiveRecord::Migration
  def self.up
    zones = {}
    Zone.find(:all).each do |zone|
      hash = zone.provider_account_id.to_s + ':'+ zone.name.to_s
      zones[hash] = zone
    end

    Instance.find(:all).each do |instance|
      hash = instance.provider_account_id.to_s + ':' + instance.zone.to_s
      instance.update_attributes!({ :zone_id => zones[hash].id }) unless zones[hash].nil?
    end
  end

  def self.down
    Instance.find(:all).each do |instance|
      zone = Zone.find(instance.zone_id)
      instance.update_attributes!({ :zone => zone.name }) unless zone.nil?
    end
  end
end
