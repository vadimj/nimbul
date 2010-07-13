class Parent::OperationsController < ApplicationController
    parent_resources :server, :server_task
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @operations  = Operation.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter])

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

	def show
		@operation = Operation.find(params[:id], :include => [ :operation_params, :security_groups ])
    @operation_params = @operation.operation_params
		@security_groups = @operation.security_groups

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @operation }
		end
	end

	def new
		@operation = Operation.new
		@operation.operation_params.build( :name => 'ROLES' )

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @operation }
		end
	end

	# GET /operations/1/edit
	def edit
		@operation = Operation.find(params[:id])
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @operation }
		end
	end

	def create
		@operation = Operation.new(params[:operation])

		respond_to do |format|
			if @operation.save
				flash[:notice] = 'Operation was successfully created.'
				o = @operation
				AuditLog.create_for_parent(
					:parent => parent,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "created '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
				format.html { redirect_to(@operation) }
				format.xml  { render :xml => @operation, :status => :created, :location => @operation }
			else
				format.html { render :action => "new" }
				format.xml  { render :xml => @operation.errors, :status => :unprocessable_entity }
			end
		end
	end

	def destroy
		@cluster = Cluster.find(params[:cluster_id])
		@operation = Operation.find(params[:id])
		@operation.destroy

		respond_to do |format|
			format.html { redirect_to @cluster }
			format.xml  { head :ok }
			format.js
		end
	end

    def control
        joins = nil
	    conditions = nil
	    @operations  = Operation.find_all_by_parent(parent, params[:operation_ids], params[:page], joins, conditions, params[:sort])
	    
        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		zone = parent.zones.find(params[:zone_id]) unless params[:zone_id].blank?
        prefix = params[:command_parameter]
        
        @error_message = ''
        @volumes = []
        if @operations.size == 0
		    @error_message = "No operations are specified."
        else
	        @operations.each do |operation|
				volume = nil
				begin
					if params[:command] == 'restore'
						volume = operation.restore!(zone, prefix)
						@volumes << volume if !volume.nil? and volume.errors.empty?
					end
					operation.delete! if params[:command] == 'destroy'
		            operation.enable! if params[:command] == 'enable'
		            operation.disable! if params[:command] == 'disable'
				rescue
					operation.errors.add(:state, "Failed to #{params[:command]} operation '#{operation.name}': #{$!}")
				end
	            unless operation.errors.empty?
					@error_message += '<br/>' + operation.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
	            end
	            unless volume.nil? or volume.errors.empty?
					@error_message += '<br/>' + volume.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
				@message = "#{params[:command]} operation(s) - success" if @error_message.blank?
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
