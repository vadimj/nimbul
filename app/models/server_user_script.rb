# Class holding user-data info
class ServerUserScript
	attr_accessor :account, :cluster, :server, :data

	def initialize
		@server  = nil
		@data    = nil
	end

	def security_groups
		return nil if @server.nil?
		groups = @server.security_groups.collect { |g| g.name }
		groups << account.default_security_group if not account.default_security_group.blank?
	end
	
	def cluster
		server.cluster
	end

	def account
		cluster.provider_account
	end
end
