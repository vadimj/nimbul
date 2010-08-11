class Parent::SnapshotsController < ApplicationController
    parent_resources :provider_account, :cluster
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @snapshots  = CloudSnapshot.search_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter])

        @parent_type = parent_type
        @parent = parent
	    @controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @snapshots }
	        format.js
	    end
    end
    def list
        index
    end

	def show
		@snapshot = CloudSnapshot.find(params[:id], :include => [ :snapshot_params, :security_groups ])
    	@snapshot_params = @snapshot.snapshot_params
		@security_groups = @snapshot.security_groups

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @snapshot }
		end
	end

	def new
		@snapshot = CloudSnapshot.new
		@snapshot.snapshot_params.build( :name => 'ROLES' )

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @snapshot }
		end
	end

	# GET /snapshots/1/edit
	def edit
		@snapshot = CloudSnapshot.find(params[:id])
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @snapshot }
		end
	end

    def control
        joins = nil
	    conditions = nil
	    @snapshots  = CloudSnapshot.search_by_parent(parent, params[:snapshot_ids], params[:page], joins, conditions, params[:sort], nil, :clusters)
	    
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
        if @snapshots.size == 0
		    @error_message = "No snapshots are specified."
        else
	        @snapshots.each do |snapshot|
				volume = nil
				begin
					if params[:command] == 'restore'
						volume = snapshot.restore!(zone, prefix)
						@volumes << volume if !volume.nil? and volume.errors.empty?
					end
					snapshot.delete! if params[:command] == 'destroy'
		            snapshot.enable! if params[:command] == 'enable'
		            snapshot.disable! if params[:command] == 'disable'
				rescue
					snapshot.errors.add(:state, "Failed to #{params[:command]} snapshot '#{snapshot.name}': #{$!}")
				end
	            unless snapshot.errors.empty?
					@error_message += '<br/>' + snapshot.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
	            end
	            unless volume.nil? or volume.errors.empty?
					@error_message += '<br/>' + volume.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
				@message = "#{params[:command]} snapshot(s) - success" if @error_message.blank?
			end
		end

        @controls_enabled = true
        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
				@snapshots.each do |snapshot|
					p = parent
					o = snapshot
					auditable_id = snapshot.destroyed ? nil : o.id
					AuditLog.create_for_parent(
						:parent => p,
						:auditable_id => auditable_id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "#{params[:command]} '#{o.name}'",
						:changes => o.tracked_changes,
						:force => true
					)
				end
				@volumes.each do |volume|
					p = parent
					o = volume
					AuditLog.create_for_parent(
						:parent => p,
						:auditable_id => o.id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "created '#{o.name}' from '#{o.parent_cloud_id}'",
						:changes => o.tracked_changes,
						:force => true
					)
				end
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
