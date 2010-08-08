require 'erb'

class Server::UserScriptController < ApplicationController
  SCRIPT_PATH = File.join(RAILS_ROOT, 'app', 'views', 'server', 'user_script')
  
  before_filter :login_required
  require_role  :admin,
                :unless => "params[:id].nil? or current_user.has_server_access?(Server.find(params[:id])) "

  def show
    @server = Server.find(params[:id], :include => { :cluster => :provider_account })
		@cluster = @server.cluster
		@provider_account = @cluster.provider_account
		@server_script_data = Server::UserScriptController.generate(@server)
		
		# remove password values before rendering
		@server.parameters.each do |p|
			@server_script_data.sub!(p.value.sub("'","\'"),'[FILTERED]') if p.is_protected? and !p.value.blank?
		end
		
    unless @provider_account.messaging_url.blank?
      @server_script_data.sub!(@provider_account.messaging_url, '[FILTERED]')
    end
  end

  def self.generate(server, compress = false)
    loader_template  = File.join(SCRIPT_PATH, 'loader')
    payload_template = File.join(SCRIPT_PATH, 'generate.erb')

    user_script = ServerUserScript.new(server)
    
    erb = ERB.new(File.read(payload_template), nil, "%-")
    payload = erb.result(binding)
    if compress
      loader = File.read(loader_template)
      StringIO.open(loader, 'ab') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write payload
        gz.close
      end
      payload = loader
    end
    return payload
  end
end
