class ResourceBundle::ServerResourcesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_resource_bundle_access?(ResourceBundle.find(params[:resource_bundle_id])) "

	def prepare_resources
		@zones = []
		@addresses = []
		@volumes = []
		@snapshots = []
		@resource_bundle.server.available_resources(@resource_bundle.zone_id) do |z,a,v,s|
			@zones = z
			@addresses = a
			@volumes = v
			@snapshots = s
		end	

		if @server_resource.is_a?(ServerAddress)
			if @addresses.empty?
				@error_message = "All available addresses have been allocated.<br/>Request additional addresses from the Account Administrator."
			end
        else
			@volume_classes = []
			@volume_resources = []
	        @mount_type = params[:mount_type]
	        mount_types = SERVER_VOLUME_MOUNT_TYPES.collect{|t| t if (@mount_type.blank? || @mount_type == t.value)}.compact
			CloudResource.classes_and_resources([@volumes, @snapshots], mount_types) do |c, r|
				@volume_classes = c
				@volume_resources = r
			end
			if @volume_resources.empty?
				@error_message = "All available storage has been allocated.<br/>Consider placing your Launch Configuration in a different zone or request additional storage from the Account Administrator."
			end
		end
	end

	def new
        @resource_bundle = ResourceBundle.find(params[:resource_bundle_id])
        @class_type = params[:class_type] unless params[:class_type].blank?
        @server_resource = ServerResource.factory(@class_type)

		self.prepare_resources

        respond_to do |format|
			if @error_message.blank?
				format.html
				format.xml  { render :xml => @server_resource }
				format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
				format.xml  { render :xml => @resource_bundle.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end		

    def create
        @resource_bundle = ResourceBundle.find(params[:resource_bundle_id])
        server_resource_params = params[:server_resource]
        
        # find the resource
        if server_resource_params[:cloud_resource_id].blank?
            @error_message = "Please specify a resource."
        else
            @cloud_resource = CloudResource.find(server_resource_params[:cloud_resource_id])
        end
        
        # check on the ability to mount it
        mount_type = server_resource_params[:mount_type]
        if mount_type.blank?
            @error_message = "Please specify mount type."
        else
	        mount_type = mount_type.constantize
	        mount_type.can_mount?(@resource_bundle, @cloud_resource) do |can_mount, msg|
				@error_message = msg unless can_mount
	        end
        end

		# construct the server resource based on this cloud resource
        if @error_message.blank?
			if current_user.has_cloud_resource_access?(@cloud_resource)
				@server_resource = case server_resource_params[:class_type]
					when 'ServerAddress' then @resource_bundle.addresses.build(server_resource_params)
					when 'ServerVolume' then @resource_bundle.volumes.build(server_resource_params)
				end
			else
			    @error_message = "You don't have permission to mount resource '#{@cloud_resource.name}'"
			end
		end

		self.prepare_resources

        respond_to do |format|
			if @error_message.blank? and @server_resource.save
				@message = "Added resource '#{@cloud_resource.name}' the Resource Bundle"
				flash[:notice] = @message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
				format.xml  { render :xml => @server_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def update
        @resource_bundle = ResourceBundle.find(params[:resource_bundle_id])
        @server_resource = @resource_bundle.server_resources.find(params[:id])
        @cloud_resource = CloudResource.find(params[:cloud_resource_id]) if params[:cloud_resource_id]
        
        if @cloud_resource.nil? or current_user.has_cloud_resource_access?(@cloud_resource)
            # proceed
        else
            @server_resource.errors.add( :cloud_resource_id, "You are not allowed to allocate cloud resource '#{@cloud_resource.name}' [#{@cloud_resource.id}]." )
        end
        
        # TODO: capture all possible updates - ugly, needs re-thinking
        params[:server_resource] ||= params[:server_address] || params[:server_volume]
        
        respond_to do |format|
			if @server_resource.errors.empty? and @server_resource.update_attributes(params[:server_resource])
				@message = "Updated server resource."
				flash[:notice] = @message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
				format.json { render :json => @server_resource }
			else
				@error_message ||= @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                @server_resource.status_message = @server_resource.errors.collect{|attr,msg| "#{attr.humanize} - #{msg}"}.join('\n')
				flash[:error] = @error_message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
				format.xml  { render :xml => @server_resource.errors, :status => :unprocessable_entity }
				format.js
				format.json { render :json => @server_resource, :status => :unprocessable_entity }
			end
        end
    end

    def destroy
        @resource_bundle = ResourceBundle.find(params[:resource_bundle_id])
        @server_resource = @resource_bundle.server_resources.find(params[:id])
        
        respond_to do |format|
			if @server_resource.destroy
				flash[:notice] = "Removed '#{@server_resource.cloud_resource.name}'."
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @resource_bundle, :anchor => params[:anchor] }
 				format.xml  { render :xml => @resource_bundle.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
end

