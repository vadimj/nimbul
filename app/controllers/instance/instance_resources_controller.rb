class Instance::InstanceResourcesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_instance_access?(Instance.find(params[:instance_id])) "

	def prepare_resources
        @instance ||= Instance.find(params[:instance_id])
        @provider_account = ProviderAccount.find(@instance.provider_account_id, :include => [ :security_groups, :cloud_resources ])

        @cloud_resources = []
        @addresses = []
        @volumes = []
        @snapshots = []
        
		# gather available cloud resources
        if current_user.has_provider_account_access?(@provider_account)
			@cloud_resources = @provider_account.cloud_resources
        else
	        if @instance.server_id
				@server = Server.find(@instance.server_id)
				@cluster = Cluster.find(@server.cluster_id, :include => :cloud_resources) if @server
				if @cluster and current_user.has_cluster_access?(@cluster)
					@cloud_resources = @cluster.cloud_resources
				end
			end
        end
        
        # select only those that are available in instance's zone
        @cloud_resources = @cloud_resources.select{ |cr| !cr.class.default_mount_type.constantize.care_about_zone? or cr.zone_id ==  @instance.zone_id }

		# split available cloud resources into types
		if @cloud_resources.length > 0
			@addresses = @cloud_resources.select{ |cr| cr.class_type == 'CloudAddress' }
			@volumes = @cloud_resources.select{ |cr| cr.class_type == 'CloudVolume' }
			@snapshots = @cloud_resources.select{ |cr| cr.class_type == 'CloudSnapshot' }
		end
	end

	def new
        @instance = Instance.find(params[:instance_id])
        @cluster = @instance.cluster
        @instance_resource = InstanceResource.new
        
		respond_to do |format|
			format.html
			format.xml  { render :xml => @instance_resource }
			format.js
		end
    end		

    def create
        @instance = Instance.find(params[:instance_id])
        instance_resource_params = params[:instance_resource]
        
        # find the cloud resource
        if instance_resource_params[:cloud_resource_id].blank?
            @error_message = "Please specify a resource."
        else
            @cloud_resource = CloudResource.find(instance_resource_params[:cloud_resource_id])
        end
        
        # check on the ability to mount this resource
        allow_multiple_allocations = true
        mount_type = instance_resource_params[:mount_type]
        if mount_type.blank?
            @error_message = "Please specify mount type."
        else
	        mount_type = mount_type.constantize
	        mount_type.can_mount?(@instance, @cloud_resource, allow_multiple_allocations) do |can_mount, msg|
				@error_message = msg unless can_mount
	        end
        end

		# construct the instance resource based on this cloud resource
        if @error_message.blank?
			if current_user.has_cloud_resource_access?(@cloud_resource)
				@instance_resource = case instance_resource_params[:class_type]
					when 'InstanceAddress' then @instance.addresses.build(instance_resource_params)
					when 'InstanceVolume' then @instance.volumes.build(instance_resource_params)
				end
			else
			    @error_message = "You don't have permission to mount resource '#{@cloud_resource.name}'"
			end
		end
        
        self.prepare_resources
        
        respond_to do |format|
			if @error_message.blank? and @instance_resource.save
				@message = "Added resource '#{@cloud_resource.name}' to instance '#{@instance.name}'"
				flash[:notice] = @message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= @instance_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
				format.xml  { render :xml => @instance_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def update
        @instance = Instance.find(params[:instance_id], :include => :instance_resources)
        @instance_resource = @instance.instance_resources.find(params[:id])
        
        # TODO: capture all possible updates - ugly, needs re-thinking
        params[:instance_resource] ||= params[:instance_address] || params[:instance_volume]
        attrs = params[:instance_resource]
        
        @cloud_resource = CloudResource.find(attrs[:cloud_resource_id]) unless attrs[:cloud_resource_id].blank?
        if @cloud_resource.nil? or current_user.has_cloud_resource_access?(@cloud_resource)
            # proceed
        else
            @instance_resource.errors.add( :cloud_resource_id, "You are not allowed to allocate cloud resource '#{@cloud_resource.name}' [#{@cloud_resource.id}]." )
        end
        
        respond_to do |format|
			if @instance_resource.errors.empty? and @instance_resource.update_attributes(attrs)
				@message = "Updated instance resource for '#{@instance.name}'."
				flash[:notice] = @message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
				format.json { render :json => @instance_resource }
			else
				@error_message ||= @instance_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				@instance_resource.status_message = @instance_resource.errors.collect{|attr,msg| "#{attr.humanize} - #{msg}"}.join('\n')
				flash[:error] = @error_message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
				format.xml  { render :xml => @instance_resource.errors, :status => :unprocessable_entity }
				format.js
				format.json { render :json => @instance_resource, :status => :unprocessable_entity }
			end
        end
    end

    def destroy
        @instance = Instance.find(params[:instance_id])
        @instance_resource = @instance.instance_resources.find(params[:id])
        
        respond_to do |format|
			if @instance_resource.destroy
				flash[:notice] = "Removed '#{@instance_resource.cloud_resource.name}' from '#{@instance.name}'."
                format.html { redirect_to @instance, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @instance_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
 				format.xml  { render :xml => @instance.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def attach
        @instance = Instance.find(params[:instance_id])
        @instance_resource = @instance.instance_resources.find(params[:id], :include => :cloud_resource)
        
        respond_to do |format|
			if @instance_resource.attach!
				msg = "Attaching '#{@instance_resource.cloud_resource.name}' to instance #{@instance.name}"
				msg += " as #{@instance_resource.mount_point}" unless @instance_resource.mount_point.blank?
				flash[:notice] = msg
                format.html { redirect_to @instance, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @instance_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
 				format.xml  { render :xml => @instance.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def detach
        @instance = Instance.find(params[:instance_id])
        @instance_resource = @instance.instance_resources.find(params[:id], :include => :cloud_resource)
        
        respond_to do |format|
			if @instance_resource.detach!
				msg = "Detaching '#{@instance_resource.cloud_resource.name}' from instance #{@instance.name}"
				msg += ", was mounted as #{@instance_resource.mount_point}" unless @instance_resource.mount_point.blank?
				flash[:notice] = msg
                format.html { redirect_to @instance, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @instance_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @instance, :anchor => params[:anchor] }
 				format.xml  { render :xml => @instance.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
end

