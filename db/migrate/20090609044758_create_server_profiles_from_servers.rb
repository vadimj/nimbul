class CreateServerProfilesFromServers < ActiveRecord::Migration
  def self.up
    admin = User.find_by_login('admin')
    servers = Server.find(:all)
    servers.each do |s|
      if s.cluster
        account = s.cluster.provider_account
      else
        account = ProviderAccount.find(s.provider_account_id)
      end
      
      account_admins = account.users
      
      sp = ServerProfile.new({
        :name => s.name,
        :description => "#{s.name} Profile",
        :creator_id => admin.id,
      })
      sp.save(false)
      sp.reload
      
      account_admins.each do |user|
        sp.server_profile_user_accesses.build({
          :user_id => user.id,
          :role => 'admin',
        })
      end
      sp.save(false)
      sp.reload
      
      spr = sp.server_profile_revisions.build({
        :revision => 0,
        :creator_id => admin.id,
        :commit_message => "Initial import from Servers",
        :image_id => s.image_id,
        :startup_script => s.startup_script,
        :instance_type => s.type,
      })
      spr.servers << s
      spr.save(false)
      spr.reload

      s.server_parameters.each do |p|
        par = spr.server_profile_revision_parameters.build({
          :position => p.position,
          :name => p.name,
          :value => p.value,
          :is_protected => p.is_protected?,
        })
        par.save(false)
      end
      
    end
  end

  def self.down
    ServerProfile.find(:all).each do |sp|
      sp.destroy
    end
  end
end
