class AutoScalingGroup::TriggersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_auto_scaling_group_access?(AutoScalingGroup.find(params[:auto_scaling_group_id]))"

	def index
        @auto_scaling_group = AutoScalingGroup.find(params[:auto_scaling_group_id])

		joins = nil
		conditions = [
			'auto_scaling_group_id = ?',
			@auto_scaling_group.id
		]

		@auto_scaling_triggers = AutoScalingTrigger.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            format.html { render :template => 'auto_scaling_triggers/index' }
            format.xml  { render :xml => @auto_scaling_groups }
            format.js   { render :template => 'auto_scaling_triggers/index', :layout => false }
        end
	end
	def list
		index
	end
	
    def new
        @auto_scaling_group   = AutoScalingGroup.find(params[:auto_scaling_group_id])
        @auto_scaling_trigger = AutoScalingTrigger.new

        respond_to do |format|
            format.html { render :template => 'auto_scaling_triggers/new' }
            format.xml  { render :xml => @auto_scaling_trigger}
            format.js
        end
    end
    
    def create
        @auto_scaling_group = AutoScalingGroup.find(params[:auto_scaling_group_id])
        trigger = params[:auto_scaling_trigger]
        @auto_scaling_trigger = @auto_scaling_group.auto_scaling_triggers.build(trigger)
        redirect_url = provider_account_url(@auto_scaling_group.provider_account_id, :anchor => :auto_scaling)

		@error_messages = []
        respond_to do |format|
            if !params[:cancel_button].blank? || @auto_scaling_trigger.save
				if params[:cancel_button].blank?
	                @message = "Created Auto Scaling Trigger '#{@auto_scaling_trigger.name}'"
	                flash[:notice] = @message
				end
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @auto_scaling_trigger, :status => :created, :location => @auto_scaling_trigger }
                format.js
            else
				@error_messages += @auto_scaling_trigger.errors.collect{ |attr,msg| attr.humanize+' - '+msg }
                flash[:error] = @error_messages.join('<br/>')
                format.html { render :action => "new" }
                format.xml  { render :xml => @auto_scaling_trigger.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

    def edit
        @auto_scaling_group = AutoScalingGroup.find(params[:auto_scaling_group_id], :include => [ :auto_scaling_triggers ])
        @auto_scaling_trigger = @auto_scaling_group.auto_scaling_triggers.detect{ |ast| ast.id == params[:id].to_i }
		@auto_scaling_trigger.parse_ui_from_values
		
        respond_to do |format|
            format.html
            format.xml  { render :xml => @auto_scaling_trigger, :location => @auto_scaling_trigger }
            format.js
        end
    end

    def update
        @auto_scaling_group = AutoScalingGroup.find(params[:auto_scaling_group_id], :include => [ :auto_scaling_triggers ])
        @auto_scaling_trigger = @auto_scaling_group.auto_scaling_triggers.detect{ |ast| ast.id == params[:id].to_i }
        redirect_url = provider_account_url(@auto_scaling_group.provider_account_id, :anchor => :auto_scaling)
		@auto_scaling_trigger.attributes =  params[:auto_scaling_trigger]

		@error_messages = []
        respond_to do |format|
            if !params[:cancel_button].blank? or (@auto_scaling_trigger.update_attributes(params[:auto_scaling_trigger]) and @auto_scaling_trigger.update_cloud)
				if params[:cancel_button].blank?
					@message = "Updated Auto Scaling Trigger '#{@auto_scaling_trigger.name}'"
					flash[:notice] = @message
				end
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @auto_scaling_trigger, :status => :updated, :location => @auto_scaling_trigger }
                format.js
            else
				@error_messages += @auto_scaling_trigger.errors.collect{ |attr,msg| attr.humanize+' - '+msg }
                flash[:error] = @error_messages.join('<br/>')
                format.html { render :action => "edit" }
                format.xml  { render :xml => @auto_scaling_trigger.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end
