require 'erb'
require 'zlib'

class Server::UserDataController < ApplicationController
  USERDATA_PATH = File.join(RAILS_ROOT, 'app', 'views', 'server', 'user_data')
  
  before_filter :login_required
  require_role  :admin,
        :unless => "params[:id].nil? or current_user.has_server_access?(Server.find(params[:id])) "
  
  def show
    @server = Server.find(params[:id], :include => { :cluster => :provider_account})
    @cluster = @server.cluster
    @provider_account = @cluster.provider_account
    @server_user_data = Server::UserDataController.generate(@server)
    
    # remove password values before rendering
    @server.parameters.each do |p|
      @server_user_data.sub!(p.value.sub("'","\'"),'[FILTERED]') if p.is_protected? and !p.value.blank?
    end
  
    unless @provider_account.messaging_url.blank?
      @server_user_data.sub!(@provider_account.messaging_url, '[FILTERED]')
    end
  end
  
  def self.cloudrc_setup(server_or_user_data)
    cloudrc_template = File.join(USERDATA_PATH, 'cloudrc.erb')
    user_data = server_or_user_data.is_a?(ServerUserData) ? server_or_user_data : ServerUserData.new(server_or_user_data)
    ERB.new(File.read(cloudrc_template), nil, '%-').result(binding)
  end
  
  def self.generate(server, compress = false)
    cloudrc_template = File.join(USERDATA_PATH, 'cloudrc.erb')
    loader_template = File.join(USERDATA_PATH, 'loader')
    payload_template = File.join(USERDATA_PATH, 'generate.erb')
    emissary_template = File.join(USERDATA_PATH, 'emissary.erb')
    
    user_data = ServerUserData.new(server)
    
    user_data.cloudrc = cloudrc_setup(server)
    emissary_config = ERB.new(File.read(emissary_template), nil, '%-').result(binding)

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
