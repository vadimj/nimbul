class Server::ResourceBundlesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_server_access?(Server.find(params[:server_id])) "

	def prepare_resources
		@zones = []
		@addresses = []
		@volumes = []
		@snapshots = []
		@server.available_resources do |z,a,v,s|
			@zones = z
			@addresses = a
			@volumes = v
			@snapshots = s
		end	
	end

    def index
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        
   		self.prepare_resources

	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @instances }
	        format.js
	    end
    end
    
    def list
        index
    end

    def make_default
        @server = Server.find(params[:server_id])
        @resource_bundle = @server.resource_bundles.find(params[:id])
        @server.default_resource_bundle = @resource_bundle
		index
    end

	def new
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @resource_bundle = ResourceBundle.new

   		self.prepare_resources
        
		respond_to do |format|
			format.html
			format.xml  { render :xml => @resource_bundle }
			format.js
		end
    end		

    def create
        @server = Server.find(params[:server_id], :include => [ :resource_bundles ])
        @cluster = @server.cluster
        
   		self.prepare_resources

		@resource_bundle = @server.resource_bundles.build(params[:resource_bundle])
		@resource_bundle.is_default = @server.default_resource_bundle.nil?

        respond_to do |format|
			if @error_message.blank? and @resource_bundle.save
				@server.default_resource_bundle = @resource_bundle if (@server.resource_bundles.size == 1)
				@message = "Added resource bundle to #{@server.name}"
				flash[:notice] = @message
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@resource_bundle.addresses.each do |address|
					@error_message ||= address.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>') unless address.errors.empty?
				end
				@resource_bundle.volumes.each do |volume|
					@error_message ||= volume.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>') unless volume.errors.empty?
				end
				@error_message ||= @resource_bundle.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
				format.xml  { render :xml => @resource_bundle.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def update
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @resource_bundle = @server.resource_bundles.find(params[:id])
        
   		self.prepare_resources

        respond_to do |format|
			if @error_message.blank? and @resource_bundle.update_attributes(params[:resource_bundle])
				@message = "Updated resource for #{@server.name}"
				flash[:notice] = @message
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= @resource_bundle.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
				format.xml  { render :xml => @resource_bundle.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @resource_bundle = @server.resource_bundles.find(params[:id])

   		self.prepare_resources
        
        respond_to do |format|
			if @resource_bundle.destroy
				flash[:notice] = "Removed resource bundle from server '#{@server.name}'."
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @resource_bundle.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
 				format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def sort
        @server = Server.find(params[:server_id])
        params[:resource_bundles].each_with_index do |id, index|
            @server.resource_bundles.update_all(['position=?', index+1], ['id=?', id])
        end
        render :nothing => true
    end
    
	def start
        @server = Server.find(params[:server_id], :include => :resource_bundles)
        @resource_bundle = @server.resource_bundles.detect{ |rb| rb.id == params[:id].to_i }
        @instances = []

        options = {
            :anchor => :launch_configurations,
        }
	    redirect_url = send("server_url", @server, options)

        @error_messages = []
        if @resource_bundle.nil?
		    @error_messages = [ "Launch configuration [#{params[:id]}] doesn't belong to server '#{@server.name}' [#{@server.id}]" ]
        else
			count = 1
	        start_options = { :user_id => current_user.id }
			@instances = @resource_bundle.start!(count, start_options)
			@instances.each do |instance|
				@error_messages += instance.errors.collect{ |attr,msg| attr.humanize+' - '+msg } unless instance.errors.empty?
	        end
	        @error_messages += @resource_bundle.errors.collect{ |attr,msg| attr.humanize+' - '+msg } unless @resource_bundle.errors.empty?
		end

        respond_to do |format|
            if @error_messages.empty?
                flash[:notice] = "Started server '#{@server.name}' [#{@server.id}] with launch configuration [#{@resource_bundle.id}]"
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_messages.join('<br/>')
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @error_messages, :status => :unprocessable_entity }
                format.js
            end
        end

	end
end

