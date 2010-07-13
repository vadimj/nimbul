class AssignZonesToRegions < ActiveRecord::Migration
  def self.up
    Zone.find(:all).each do |zone|
      account = ProviderAccount.find(zone.provider_account_id) 
      region = Region.find_by_provider_id_and_name(account.provider_id, zone.name.chop)
      zone.update_attribute( :region_id, region.id ) if region 
    end
  end

  def self.down
    Zone.update_all("region_id = NULL")
  end
end
