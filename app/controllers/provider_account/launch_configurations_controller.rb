class ProviderAccount::LaunchConfigurationsController < ApplicationController
	before_filter :login_required

	require_role  :admin,
		:unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"

	# GET /provider_accounts/:provider_account_id/launch_configurations/new
	# GET /provider_accounts/:provider_account_id/launch_configurations/new.xml
	def new
		@provider_account = ProviderAccount.find(params[:provider_account_id])
		@launch_configuration = @provider_account.launch_configurations.build
		@users = User.find(:all, :order => :login)

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @launch_configuration }
		end
	end

	# POST /provider_accounts/:provider_account_id/launch_configurations/create
	# POST /provider_accounts/:provider_account_id/launch_configurations/create.xml
	def create
		@provider_account = ProviderAccount.find(params[:provider_account_id])

		if params[:lc_based_on] == 'existing'
			server = Server.find(params[:launch_configuration][:server_id])
			spr = ServerProfileRevision.find(params[:launch_configuration][:server_profile_revision_id])
			if spr.nil? or server.nil?
				@launch_configuration = nil
			else
				# getting attributes from the Server Profile
				attrs = spr.attributes.inject({}) do |h,(k,v)|
					k = k.to_sym
					h[k] = v if [
						:kernel_id,
						:ramdisk_id,
						:image_id,
						:instance_type
					].include?(k);
					h
				end
				attrs.merge!(params[:launch_configuration])
				@launch_configuration = @provider_account.launch_configurations.build(attrs)
				@launch_configuration.key_name = @provider_account.default_main_key.blank? ? server.key_name : @provider_account.default_main_key

		        # get security groups
		        groups = server.security_groups.collect{|g| g.name}
		        security_groups = (SecurityGroup.find_all_by_provider_account_id_and_name(@provider_account.id, groups))
		        unless @provider_account.default_security_group.blank?
					default_security_group = SecurityGroup.find_by_provider_account_id_and_name(@provider_account.id, @provider_account.default_security_group)
		            security_groups << default_security_group unless security_groups.include?(default_security_group)
		        end
		        @launch_configuration.security_groups = ( security_groups || [] )
			end
		else 
			@launch_configuration = @provider_account.launch_configurations.build(params[:launch_configuration])
		end
		
		@launch_configuration.created_time = Time.now
        redirect_url = provider_account_url(@provider_account.id, :action => :show, :anchor => 'auto_scaling')

	    respond_to do |format|
			if not @launch_configuration.nil? and @launch_configuration.save
				flash[:notice] = 'Launch Configuration was successfully created.'
				format.html { redirect_to redirect_url }
				format.xml  { render :xml => @launch_configuration, :status => :created, :location => @launch_configuration }
			else
				flash[:error] = 'Failed to create a Launch Configuration: ' + (@launch_configuration.cloud_message rescue '')
		        format.html { render :action => "new" }
		        format.xml  { render :xml => @launch_configuration.errors, :status => :unprocessable_entity }
		    end
		end
	end
end
