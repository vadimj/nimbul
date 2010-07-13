class ProviderAccount::AutoScalingGroupsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"

	def index
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @provider_account.refresh(params[:refresh]) if params[:refresh]

		joins = nil
		conditions = [ 'provider_account_id = ?', @provider_account.id ]

		@auto_scaling_groups   = @launch_configurations # AutoScalingGroup.search(params[:asg_search], params[:asg_page], joins, conditions, params[:asg_sort])

        respond_to do |format|
            format.html { render :template => 'auto_scaling_groups/index' }
            format.xml  { render :xml => @auto_scaling_groups }
            format.js
        end
	end

	def list
		index
	end
	
    def new
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @auto_scaling_group = AutoScalingGroup.new

        respond_to do |format|
            format.html { render :template => 'auto_scaling_groups/new' }
            format.xml  { render :xml => @auto_scaling_group}
            format.js
        end
    end
    
    def create
        @provider_account = ProviderAccount.find(params[:provider_account_id], :include => [ :launch_configurations ])
        asg_params = params[:auto_scaling_group]
        @auto_scaling_group = @provider_account.auto_scaling_groups.build(asg_params)
		@launch_configuration = @provider_account.launch_configurations.detect{|lc| lc.id == @auto_scaling_group.launch_configuration_id}
		@auto_scaling_group.launch_configuration = @launch_configuration

        @error_messages = []
		if asg_params[:zone_ids].nil? or asg_params[:zone_ids].empty?
			@error_messages << "You must specify at least one zone"
		end
        respond_to do |format|
            if @error_messages.empty? && @auto_scaling_group.save
                @message = "Created Auto Scaling Group '#{@auto_scaling_group.name}' [#{@auto_scaling_group.id}]"
                flash[:notice] = @message
	            p = @provider_account
				o = @auto_scaling_group
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
                format.html { redirect_to(@provider_account, :anchor => :auto_scaling) }
                format.xml  { render :xml => @auto_scaling_group, :status => :created, :location => @auto_scaling_group }
                format.js
            else
				@error_messages += @auto_scaling_group.errors.collect{|attr,msg| "#{attr.humanize} - #{msg}"}
                flash[:error] = @error_messages.join('<br/>')
                format.html { render :action => "new" }
                format.xml  { render :xml => @auto_scaling_group.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end
