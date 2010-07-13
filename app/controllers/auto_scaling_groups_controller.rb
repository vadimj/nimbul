class AutoScalingGroupsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_provider_account_access?( AutoScalingGroup.find(params[:id]).provider_account_id )"

    def destroy
		@auto_scaling_group = AutoScalingGroup.find(params[:id])
		@provider_account = @auto_scaling_group.provider_account
		redirect_url = provider_account_path(@provider_account, :anchor => :auto_scaling)

		@error_messages = []
        @auto_scaling_group.destroy
		@error_messages += @auto_scaling_group.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }

        respond_to do |format|
			if @error_messages.empty?
				p = @provider_account
				o = @auto_scaling_group
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

	def disable
		@auto_scaling_group = AutoScalingGroup.find(params[:id])
		@provider_account = @auto_scaling_group.provider_account

		@error_messages = []
		@auto_scaling_group.disable!
		@error_messages += @auto_scaling_group.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }

		respond_to do |format|
			if @error_messages.empty?
				p = @provider_account
				o = @auto_scaling_group
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
		@auto_scaling_group = AutoScalingGroup.find(params[:id])
		@provider_account = @auto_scaling_group.provider_account

		@error_messages = []		
		unless @auto_scaling_group.activate!
			@error_messages += @auto_scaling_group.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }
			@error_messages += @auto_scaling_group.launch_configuration.errors.collect{ |attr,msg| "Launch Configuration: #{attr.humanize} - #{msg}" } unless @auto_scaling_group.launch_configuration.errors.empty?
			@auto_scaling_group.auto_scaling_triggers.each do |trigger|
				@error_messages += trigger.errors.collect{ |attr,msg| "Trigger '#{trigger.name}': #{attr.humanize} - #{msg}" } unless trigger.errors.empty?
			end
		end

		respond_to do |format|
			if @error_messages.empty?
	            p = @provider_account
				o = @auto_scaling_group
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

	def update
		@auto_scaling_group = AutoScalingGroup.find(params[:id], :include => :provider_account)
		@provider_account = @auto_scaling_group.provider_account
		redirect_url = provider_account_url(@provider_account, :anchor => :auto_scaling)

		asg_params = params[:auto_scaling_group]
		asg_params.try :each do |k,v|
			asg_params[k] = v.chomp
		end

		@auto_scaling_group.attributes = asg_params

	    @error_messages = []
	    respond_to do |format|
			if @auto_scaling_group.update_attributes(asg_params) and @auto_scaling_group.update_cloud
				flash[:notice] = 'Group was successfully updated.'
	            p = @provider_account
				o = @auto_scaling_group
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
				format.xml  { head :ok }
				format.json { render :json => @auto_scaling_group }
				format.js
			else
                @error_messages = @auto_scaling_group.errors.collect{|attr,msg| "#{attr.humanize} - #{msg}"}
				flash[:error] = @error_messages.join('<br/>')
				format.html { redirect_to redirect_url }
				format.xml  { render :xml => @auto_scaling_group.errors, :status => :unprocessable_entity }
				format.json { render :json => @auto_scaling_group, :status => :unprocessable_entity }
				format.js
			end
		end
	end
end
