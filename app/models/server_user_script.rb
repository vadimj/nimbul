# Class holding user-data info
class ServerUserScript
  attr_accessor :server, :data

  def initialize(server)
    @server    = server
    @data      = Server::UserDataController.generate(server, false)
  end

  def security_groups
    return nil if @server.nil?
    (
      @server.security_groups.collect{ |sg| sg.name } + [ account.default_security_group ]
    ).compact.sort
  end
  
  def cluster
    server.cluster
  end

  def account
    cluster.provider_account
  end
  
  def hosts_file_url
    var = 'HOSTS_FILE_URL'
    [
      server.get_server_parameter(var),
      cluster.get_cluster_parameter(var),
      account.get_provider_account_parameter(var)
    ].compact.first
  end
  
  def available_zones
    account.zones.collect{|z| z.name }
  end
  
  def zone
    server.default_resource_bundle.zone.try(:name) rescue available_zones.sort_by(&:rand).first
  end
  
  def volumes
    volumes = server.default_resource_bundle.server_resources.select { |sr| [ServerSnapshot, ServerVolume].include? sr.class } rescue []
    volumes.inject({}) do |hash,volume|
      hash[volume.mount_point] = {
        :name    => volume.cloud_resource.name,
        :zone    => volume.cloud_resource.zone.try(:name) || self.zone || available_zones.sort_by(&:rand).first
      }
      type_data = case volume.mount_type
        when 'RestoreLatestSnapshotMountType'
          snaps = CloudSnapshot.find_all_by_provider_account_id_and_parent_cloud_id(account[:id], volume.cloud_resource.cloud_id)
          latest_snapshot = snaps.sort!{ |a,b| b.start_time <=> a.start_time }.first
          { :type => :snapshot, :id => (latest_snapshot.cloud_id rescue nil) }
        when 'RestoreSnapshotMountType'
          { :type => :snapshot, :id => (volume.cloud_resource.cloud_id rescue nil)}
        when 'MountVolumeMountType'
          { :type => :volume, :id => (volume.cloud_resource.cloud_id rescue nil)}
      else
        {}
      end
      
      hash[volume.mount_point].merge!(type_data) unless type_data.empty?
      hash
    end
  end
  
  def addresses
    addresses = server.default_resource_bundle.server_resources.select { |sr| sr.kind_of? ServerAddress } rescue []
    addresses.inject({}) do |hash,address|
      hash[address.cloud_resource.cloud_id] = address.cloud_resource.name
      hash
    end
  end
end