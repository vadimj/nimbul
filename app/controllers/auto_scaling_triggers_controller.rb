class AutoScalingTriggersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_auto_scaling_trigger_access?(AutoScalingTrigger.find(params[:id]))"

    # DELETE /auto_scaling_triggers/1
    # DELETE /auto_scaling_triggers/1.xml
    # DELETE /auto_scaling_triggers/1.js
    def destroy
		@auto_scaling_trigger = AutoScalingTrigger.find(params[:id], :include => [ :auto_scaling_group ])
		@auto_scaling_group = @auto_scaling_trigger.auto_scaling_group
		redirect_url = provider_account_path(@auto_scaling_group.provider_account_id, :anchor => :auto_scaling)

		@error_messages = []
        @auto_scaling_trigger.destroy
		@error_messages += @auto_scaling_trigger.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }

        respond_to do |format|
			if @error_messages.empty?
				p = @auto_scaling_group
				o = @auto_scaling_trigger
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
		@auto_scaling_trigger = AutoScalingTrigger.find(params[:id], :include => [ :auto_scaling_group ])
		@auto_scaling_group = @auto_scaling_trigger.auto_scaling_group
		ast_params = params[:auto_scaling_trigger]
		
		unless ast_params.nil?
			ast_params.each do |k,v|
				ast_params[k] = v.chomp
			end
		end
		
		respond_to do |format|
			if @auto_scaling_trigger.update_attributes(ast_params)
				p = @auto_scaling_group
				o = @auto_scaling_trigger
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
			else
				@error_messages = @auto_scaling_trigger.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }
				flash[:error] = @error_messages.join('<br/>')
			end
			format.json { render :json => @auto_scaling_trigger }
		end
	end

	def activate
		@auto_scaling_trigger = AutoScalingTrigger.find(params[:id], :include => [ :auto_scaling_group ])
		@auto_scaling_group = @auto_scaling_trigger.auto_scaling_group
		@provider_account = @auto_scaling_group.provider_account

		@error_messages = []
		if @auto_scaling_trigger.activate!
			@auto_scaling_trigger.reload
		else
			@error_messages = @auto_scaling_trigger.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }
		end

		@auto_scaling_trigger.reload
		respond_to do |format|
			if @error_messages.empty?
				p = @auto_scaling_group
				o = @auto_scaling_trigger
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

	def disable
		@auto_scaling_trigger = AutoScalingTrigger.find(params[:id], :include => [ :auto_scaling_group ])
		@auto_scaling_group = @auto_scaling_trigger.auto_scaling_group
		@provider_account = @auto_scaling_group.provider_account

		@error_messages = []
		if @auto_scaling_trigger.disable!
			@auto_scaling_trigger.reload
		else
			@error_messages = @auto_scaling_trigger.errors.collect{ |attr,msg| "#{attr.humanize} - #{msg}" }
		end

		respond_to do |format|
			if @error_messages.empty?
				p = @auto_scaling_group
				o = @auto_scaling_trigger
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
end
