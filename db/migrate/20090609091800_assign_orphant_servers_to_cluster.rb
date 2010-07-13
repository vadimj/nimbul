class AssignOrphantServersToCluster < ActiveRecord::Migration
  def self.up
    servers = Server.find(:all)
    servers.each do |s|
        if s.cluster_id.nil?
            account = ProviderAccount.find(s.provider_account_id)
            cluster = account.clusters[0]
            if cluster.nil?
                cluster = account.clusters.build({
                    :name => 'Default'
                })
                cluster.save(false)
            end
            cluster.servers << s
        end
    end
  end

  def self.down
  end
end
