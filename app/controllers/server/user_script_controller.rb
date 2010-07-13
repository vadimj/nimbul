require 'erb'

class Server::UserScriptController < ApplicationController
	
	def self.generate(server, data, script)
		template = File.dirname(__FILE__) + "/../../views/server/user_scripts/#{script.to_s}-script.erb"

		if not File.exists? template
			raise Exception, "Template: #{template} does not exist!"
		end

		user_script = ServerUserScript.new
		
		user_script.server  = server
		user_script.data    = data

		erb = ERB.new(File.read(template), nil, "%-")
		erb.result(binding)
	end
	
end
