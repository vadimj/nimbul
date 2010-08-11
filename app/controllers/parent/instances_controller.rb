class Parent::InstancesController < ApplicationController
    parent_resources :provider_account, :cluster, :server, :auto_scaling_group
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
		# commented out refresh from ui for performance reasons
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')
	    
        joins = nil
	    conditions = nil
	    @instances  = Instance.search_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [ :zone, :server, :user, :security_groups, :provider_account ])

        @parent_type = parent_type
        @parent = parent
	    @controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @instances }
	        format.js
	    end
    end
    def list
        index
    end
    
    def self.control_instances(instances, command)
		success = true
		messages = []
	    instances.each do |instance|
			begin
				if command == 'reboot'
					instance.reboot!
					messages << "#{instance.instance_id} rebooting"
				end
				if command == 'terminate'
					instance.terminate!
					messages << "#{instance.instance_id} terminating"
				end
			rescue  Exception => e
				msg = "#{instance.instance_id} - failed to #{command}: #{e.message}"
				messages << msg
				Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
				instance.errors.add(:state, msg)
				success = false
			end
	    end
	    yield success, instances, messages
    end
    
    def control
        joins = nil
	    conditions = nil
	    instances  = Instance.find(params[:instance_ids], :include => [ :zone, :server, :user, :security_groups, :provider_account ])
	    @instances = instances.select{ |i| current_user.has_access?(i) }
	    
        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :instances,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        @error_message = ''
        if @instances.size == 0
		    @error_message = "No instances are specified."
        else
			self.class.control_instances(@instances, params[:instance_command]) do |success, instances, msg|
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
					@error_message = msg
				end
			end
        end

        @controls_enabled = true
        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @error_message, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end
