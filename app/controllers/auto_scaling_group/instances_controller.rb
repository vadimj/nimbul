class AutoScalingGroup::InstancesController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_provider_account_access?( AutoScalingGroup.find(params[:auto_scaling_group_id]).provider_account_id )"

	# GET /auto_scaling_groups/1/instances
	# GET /auto_scaling_groups/1/instances.xml
	# GET /auto_scaling_groups/1/instances.js
	def index
        @auto_scaling_group = AutoScalingGroup.find(params[:auto_scaling_group_id])
		@provider_account = @auto_scaling_group.provider_account
		@instances = @auto_scaling_group.instances || []

        respond_to do |format|
            format.html { render :template => 'auto_scaling_group/instances/index' }
            format.xml  { render :xml => @instances }
            format.js   { render :template => 'auto_scaling_group/instances/index', :layout => false }
        end
	end

	def list
		index
	end
end
