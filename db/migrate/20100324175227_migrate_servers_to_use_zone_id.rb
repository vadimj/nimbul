require 'pp'

class MigrateServersToUseZoneId < ActiveRecord::Migration
    def self.up
        zones = {}
        Zone.find(:all).each do |zone|
            hash = zone.provider_account_id.to_s + ':' + zone.name.to_s
            zones[hash] = zone.id
        end

        Cluster.find(:all).each do |cluster|
            cluster.servers.each do |server|
                hash = cluster.provider_account_id.to_s + ':' + server.availability_zone.to_s
                server.update_attributes!({:zone_id => zones[hash]}) unless zones[hash].nil?
            end
        end
    end

    def self.down
        Server.find(:all).each do |server|
            zone = nil
            zone = Zone.find(server.zone_id) unless server.zone_id.blank?
            server.update_attributes!({:availability_zone => zone.name}) unless zone.nil?
        end
    end
end