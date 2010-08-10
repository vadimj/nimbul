# Class holding user-data info
class ServerUserData
	attr_accessor :server, :startup_scripts, :cloudrc

	def initialize(server = nil)
		@server = server
		@cloudrc = nil
		@startup_scripts = nil
	end

  def parameters
    @server.parameters
  end

  def provider_account
    @server.cluster.provider_account
  end
  
  def cluster
    @server.cluster
  end
  
  def startup_scripts
    @startup_scripts ||= [
      StartupScript.new('account_script', @server.cluster.provider_account.startup_script || ''), 
      StartupScript.new('cluster_script', @server.cluster.startup_script || ''), 
      StartupScript.new('server_script', @server.startup_script || '')
    ]
  end
end
