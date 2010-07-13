class ProviderAccount::AutoScalingController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"

	# GET /provider_accounts/1/auto_scaling
	# GET /provider_accounts/1/auto_scaling.xml
	# GET /provider_accounts/1/auto_scaling.js
	def index
		@provider_account = ProviderAccount.find(params[:provider_account_id])
		
		# We can only perform one action at a time (search XOR refresh)
		# so, using that, we can determine what to refresh based on either
		# the refresh value or the the particular search being done
		if params[:refresh]
			@refresh = params[:refresh].gsub(/_data/, 's')
			#@refresh = params[:refresh]
		elsif params[:search]
			if params[:launch_configuration_search]
				@refresh = 'launch_configurations'
			elsif params[:auto_scaling_group_search]
				@refresh = 'auto_scaling_groups'
			end
		else
			@refresh = nil
		end

		@provider_account.refresh(@refresh) unless @refresh.nil?

		joins = nil
		conditions  = [ 'provider_account_id = ?', @provider_account.id ]

		@launch_configurations = LaunchConfiguration.search(
			params[:launch_configuration_search],
			params[:launch_configuration_page], joins, conditions.dup,
			params[:sort],
			nil,
			[ :server, :server_image, :provider_account, :auto_scaling_groups ]
		) unless @refresh == 'auto_scaling_groups'
        
		@auto_scaling_groups   = AutoScalingGroup.search(
			params[:auto_scaling_group_search],
			params[:auto_scaling_group_page], joins, conditions.dup,
			params[:sort],
			nil,
			[ :launch_configuration, :provider_account, :zones, :instances ]
		) unless @refresh == 'launch_configurations'
		
		if params[:sort] =~ /launch_configuration/
			@auto_scaling_groups.sort! { |a,b| a.launch_configuration.name <=> b.launch_configuration.name }
			@auto_scaling_groups.reverse! if params[:sort] =~ /_reverse/
		end
		
		respond_to do |format|
			format.html { render :template => 'auto_scaling/index' }
			format.xml  {
				render :xml => {
					:launch_configurations => @launch_configurations,
					:auto_scaling_groups => @auto_scaling_groups
				}
			}
			format.js   {
				render :template => (@refresh ? 'auto_scaling/refresh' : 'auto_scaling/index'), :layout => false
			}
		end
	end

	def list
		index
	end
end

