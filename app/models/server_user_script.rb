# Class holding user-data info
class ServerUserScript
  attr_accessor :server, :data

  def initialize
    @server    = nil
    @data      = nil
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
  
  def volumes
    server.volumes.collect { |a| [ a.cloud_resource.cloud_id, a.mount_point] }.flatten
  end
  
  def addresses
    server.addresses.collect { |a| a.cloud_resource.cloud_id }
  end
end