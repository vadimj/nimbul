class Parent::ServersController < ApplicationController
    parent_resources :provider_account, :cluster, :instance
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"
    
    def prepare_resources
		@provider_account = parent.provider_account if parent.respond_to?('provider_account')
        @instance = Instance.find(params[:instance_id]) if params[:instance_id]
        @server.key_name = @provider_account.default_main_key unless @provider_account.default_main_key.blank?
        @parent_type = parent_type
        @parent = parent
    end

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @servers  = Server.search_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [ :instances, :resource_bundles, :default_resource_bundle, :server_profile_revision, :security_groups, :zones, :addresses, :volumes ])

        @parent_type = parent_type
        @parent = parent
	    @controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @servers }
	        format.js
	    end
    end
    def list
        index
    end

    def new
		@server = Server.new
		self.prepare_resources
        respond_to do |format|
            format.html
            format.xml  { render :xml => @server }
            format.js
        end
    end

    def create
        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :servers,
        }
        p_type = parent_type
        p = parent
        if parent.is_a?(Instance)
			p_type = 'provider_account'
			p = parent.provider_account
			options[:anchor] = 'instances'
		end
		redirect_url = send("#{ p_type }_url", p, options)
		
        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			@provider_account = parent.provider_account if parent.respond_to?('provider_account')
			@cluster ||= Cluster.find(params[:cluster_id])
	        @server = @cluster.servers.build(params[:server])
	        @server.key_name = @provider_account.default_main_key unless @provider_account.default_main_key.blank?

			# handle server profiles
			if params[:server_profile_revision_id]
				@server_profile_revision = ServerProfileRevision.find(params[:server_profile_revision_id])
				@server_profile = @server_profile_revision.server_profile
			else
				# create a new server profile based on this server
				@server_profile = @provider_account.server_profiles.build(
					{
						:name => @server.name,
						:creator_id => current_user.id,
					}
				)
				
				# add the creator as one of the admins
				@server_profile.server_profile_user_accesses.build({
					:user_id => current_user.id,
					:role => 'admin',
				})
			    @server_profile.save(false)
				
				# create the first revision based on this server
			    spr_attr =  {
			        :server_profile_id =>  @server_profile.id,
					:revision => 0,
					:creator_id => current_user.id,
					:commit_message => "Initial check in",
			    }
			    if @instance
				    spr_attr[:instance_type] = @instance.instance_type
				    spr_attr[:image_id] = @instance.image_id
			    end
				@server_profile_revision = @server_profile.server_profile_revisions.build(spr_attr)
	
			    @server_profile_revision.save(false)
				@server_profile_revision.servers << @server
			end

	        # handle server itself
	        @rb = nil
		    if @instance
				@server.security_groups = @instance.security_groups
				
				# build resource bundle
				@rb = @server.resource_bundles.build({
					:instance_id => @instance.id,
					:zone_id => @instance.zone_id,
					:is_default => true,
				})
				@rb.save
				
				# fill the bundle with resources
				@instance.instance_resources.each do |ir|
					cr = ir.cloud_resource
					sr = @rb.server_resources.build({
						:cloud_resource_id => cr.id,
						:mount_type => cr.class.default_mount_type,
						:mount_point => ir.mount_point,
					})
					sr.class_type = cr.class.server_resource_type
					sr.save
				end
				
				# make sure server knows about the instance
				@server.instances << @instance
			end

			self.prepare_resources
			respond_to do |format|
	            if @server.save
	                flash[:notice] = 'Server was successfully created.'
	                p = @server.cluster
					o = @server
					AuditLog.create_for_parent(
						:parent => p,
						:auditable_id => o.id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "created '#{o.name}'",
						:changes => o.tracked_changes,
						:force => true
					)
					format.html { redirect_to server_url(@server, :anchor => :server_profile) }
	                format.xml  { render :xml => @server, :status => :created, :location => @server }
	                format.js
	            else
					# collect errors
	                @error_message = @server.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
	                unless @rb.nil?
						unless @rb.errors.empty?
							@error_message += '<br/>Launch Configuration: ' + @rb.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
						end
						@rb.server_resources.each do |sr|
							unless sr.errors.empty?
								@error_message += '<br/>Server Resource: ' + sr.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
							end
						end
					end
	                flash[:error] = @error_message
	                format.html { render :action => "new" }
	                format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
	                format.js
	            end
			end
		end
    end

	def destroy
		@server = parent.servers.find(params[:id])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :servers,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		respond_to do |format|
            if @server.destroy
                flash[:notice] = "Server '#{@server.name}' was successfully deleted."
                p = @server.cluster
				o = @server
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => nil,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "deleted '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
				format.html { redirect_to redirect_url }
				format.xml  { head :ok }
				format.js
            else
                @error_message ||= @server.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
				format.js
            end
        end
	end

    def control
		options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :servers,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        @error_messages = []
		# prepare parameters
        count = 1
		if !params[:instance_command].blank?
			instances = Instance.find(params[:instance_ids], :include => [ :server, :provider_account ] )
			@instances = instances.select{ |i| current_user.has_instance_access?(i) }
			Parent::InstancesController.control_instances(@instances, params[:instance_command]) do |success, instances, msg|
				@instances = instances
				if success
					@message = msg
					@instances.each do |i|
						p = i.server.nil? ? parent : i.server
						o = i
						AuditLog.create_for_parent(
							:parent => p,
							:auditable_id => o.id,
							:auditable_type => o.class.to_s,
							:auditable_name => o.name,
							:author_login => current_user.login,
							:author_id => current_user.id,
							:summary => "#{params[:instance_command]} '#{o.name}'",
							:changes => o.tracked_changes,
							:force => true
						)
					end
				else
					@error_messages << msg
				end
			end
		else
	        joins = nil
		    conditions = nil
		    @servers  = Server.find(params[:server_ids], :include => [ :resource_bundles ])
	
		    if params[:instance_start_count]
		        count = params[:instance_start_count].to_i
				count = 10 if count > 10
			end
			dns_active = (params[:skip_dns_leases][0].to_i == 1 rescue false) ? false : true
	
	        start_options = { :user_id => current_user.id, :dns_active => dns_active }
	
	        @instances = []
	        if @servers.size == 0
			    @error_messages << "No servers are specified."
	        else
		        @servers.each do |server|
					server_instances = server.start!(count, start_options) if params[:command] == 'start'
					server_instances.each do |instance|
						@error_messages += instance.errors.collect{ |attr,msg| attr.humanize+' - '+msg } unless instance.errors.empty?
					end
					@error_messages += server.errors.collect{ |attr,msg| attr.humanize+' - '+msg } unless server.errors.empty?
					@instances += server_instances
				end
	        end
			@message = "Starting server(s) "+@servers.collect{ |s| "'"+s.name+"'" }.join(', ')
			# TODO - disable for now
			@instances = []
		end	
	    
	    @controls_enabled = true
        respond_to do |format|
            if @error_messages.empty?
                flash[:notice] = @message
                @servers.each do |s|
	                p = s.cluster
					o = s
					AuditLog.create_for_parent(
						:parent => p,
						:auditable_id => o.id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "started #{count} instance(s) of '#{o.name}'",
						:changes => o.tracked_changes,
						:force => true
					)
                end
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_messages.join('<br/>')
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @error_message, :status => :unprocessable_entity }
                format.js
            end
        end
    end

end
