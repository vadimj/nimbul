# Class holding user-data info
class ServerUserData
	attr_accessor :server, :parameters, :startup_scripts

	def initialize
		@server = nil
		@parameters = []
		@startup_scripts = []
	end

end
