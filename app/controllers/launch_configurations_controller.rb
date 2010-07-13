class LaunchConfigurationsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_provider_account_access?(LaunchConfiguration.find(params[:id]).try(:provider_account))"

	def load_configs
		joins = nil
		conditions  = [ 'provider_account_id = ?', @provider_account.id ]

        @launch_configurations = LaunchConfiguration.search(
			params[:launch_configuration_search],
			params[:launch_configuration_page], joins, conditions.dup,
			params[:sort],
			nil,
			[ :server_image, :provider_account, :auto_scaling_groups ]
		)
    end

	def get_server_attributes(server_id, server_profile_revision_id = nil)
		attrs = {}
		server = Server.find(server_id)
		spr = ServerProfileRevision.find(server_profile_revision_id || server.try(:server_profile_revision_id))

		unless spr.nil?
			needed_keys = [ :kernel_id, :image_id, :ramdisk_id, :instance_type ]
			attrs = spr.attributes.inject({}) { |h,(k,v)| h[k.to_sym] = v if needed_keys.include?(k.to_sym) && v; h }
			attrs[:user_data] = spr.startup_script
			attrs[:key_name] = @provider_account.default_main_key.blank? ? server.key_name : @provider_account.default_main_key
			attrs[:server_id] = server_id
			attrs[:server_profile_revision_id] = server.try :server_profile_revision_id
		end

		return attrs
	end

	def associate
		@launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

        redirect_url = provider_account_url(@provider_account, :anchor => 'auto_scaling')
		return redirect_to(redirect_url) if @launch_configuration.locked?

		lc_params = params[:launch_configuration]
		@launch_configuration.attributes = get_server_attributes(lc_params[:server_id]).merge!(lc_params)

		respond_to do |format|
			if @launch_configuration.try :save
				p = @provider_account
				o = @launch_configuration
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "associated '#{o.name}' with server [#{lc_params[:server_id]}]",
					:changes => o.tracked_changes,
					:force => false
				)
				format.html { redirect_to provider_account_url(@provider_account, :anchor => :auto_scaling) }
				format.json { render :json => @launch_configuration }
				format.js
			else
				flash[:error] = 'Failed to associate to server: ' + (@launch_configuration.try(:cloud_message) || 'unknown problem')
			end
		end
	end

	# GET /launch_configurations/1
	# GET /launch_configurations/1.xml
	def show
		@launch_configuration = LaunchConfiguration.find(params[:id], :include => [ :security_groups, :block_device_mappings ])
		@provider_account = @launch_configuration.provider_account

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @launch_configuration }
		end
	end

	def disable
		@launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

		@error_messages = []
		@launch_configuration.disable!
		@error_messages += @launch_configuration.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }
		load_configs

		respond_to do |format|
			if @error_messages.empty?
				p = @provider_account
				o = @launch_configuration
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "disabled '#{o.name}'",
					:changes => o.tracked_changes,
					:force => false
				)
			else
				flash[:error] = @error_messages.join('<br/>')
			end
			format.html { redirect_to provider_account_url(@provider_account, :anchor => :auto_scaling) }
			format.js
		end
	end

	def activate
		@launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

		@error_messages = []
		@launch_configuration.activate!
		@error_messages += @launch_configuration.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }

		load_configs

		respond_to do |format|
			if @error_messages.empty?
	            p = @provider_account
				o = @launch_configuration
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "activated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => false
				)
			else
				flash[:error] = @error_messages.join('<br/>')
			end
			format.html { redirect_to provider_account_url(@provider_account, :anchor => :auto_scaling) }
			format.js
		end
	end

	# GET /launch_configurations/1/edit
	def edit
		@launch_configuration = LaunchConfiguration.find(params[:id], :include => [ :security_groups, :block_device_mappings ])
		@provider_account = @launch_configuration.provider_account
		@cluster = @launch_configuration.try(:server, :cluster)

        redirect_url = provider_account_url(@provider_account, :anchor => 'auto_scaling')
		return redirect_to(redirect_url) if @launch_configuration.locked?

		respond_to do |format|
			format.html # edit.html.erb
		end
	end

	# GET /launch_configurations/1
	def show
		@launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

		respond_to do |format|
			format.html # show.html.erb
			format.json { render :json => @launch_configuration }
			format.xml  { render :xml => @launch_configuration }
		end
	end

    # DELETE /launch_configurations/1
    # DELETE /launch_configurations/1.xml
    # DELETE /launch_configurations/1.js
    def destroy
        @launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

        redirect_url = provider_account_url(@provider_account, :anchor => 'auto_scaling')
		return redirect_to(redirect_url) if @launch_configuration.active?

		@error_messages = []
        @launch_configuration.destroy
		@error_messages += @launch_configuration.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }

        respond_to do |format|
			if @error_messages.empty?
				p = @provider_account
				o = @launch_configuration
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
			else
				flash[:error] = @error_messages.join('<br/>')
			end
            format.html { redirect_to redirect_url }
            format.xml  { head :ok }
            format.js
        end
    end

	# PUT /auto_scaling_triggers/1
	# PUT /auto_scaling_triggers/1.json
	def update
		@launch_configuration = LaunchConfiguration.find(params[:id])
		@provider_account = @launch_configuration.provider_account

        redirect_url = provider_account_url(@provider_account, :anchor => 'auto_scaling')
		return redirect_to(redirect_url) if @launch_configuration.active?

		attrs = lc_params = params[:launch_configuration]
		if params[:lc_based_on] == 'existing'
			attrs = get_server_attributes(lc_params[:server_id], lc_params[:server_profile_revision_id]).merge!(lc_params)
		end

		@launch_configuration.attributes = attrs

	    respond_to do |format|
			if @launch_configuration.try(:save)
				flash[:notice] = 'Launch Configuration was successfully updated.'
	            p = @provider_account
				o = @launch_configuration
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "updated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => false
				)
				format.html { redirect_to redirect_url }
				format.xml  { render :xml => @launch_configuration, :status => :updated, :location => @launch_configuration }
			else
				flash[:error] = 'Failed to update a Launch Configuration: ' + (@launch_configuration.try(:cloud_message) || 'unknown problem')
		        format.html { render :action => :edit }
		        format.xml  { render :xml => @launch_configuration.errors, :status => :unprocessable_entity }
		    end
		end
	end
end
