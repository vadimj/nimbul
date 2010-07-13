class Parent::VolumesController < ApplicationController
    parent_resources :provider_account, :cluster
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @volumes  = CloudVolume.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [ :clusters, :instance, :zone ])

        @parent_type = parent_type
        @parent = parent
	    @controls_enabled = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @volumes }
	        format.js
	    end
    end
    def list
        index
    end
    
    def new
        @snapshots = parent.snapshots.collect{ |s| s if s.is_enabled?}.compact.sort{ |a,b| a.name.downcase <=> b.name.downcase }
        @volume = CloudVolume.new

        respond_to do |format|
            format.html
            format.xml  { render :xml => @volume }
            format.js
        end
    end

    def create
        @volume = parent.volumes.build(params[:volume])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		respond_to do |format|
            if @volume.allocate!
                flash[:notice] = 'Volume was successfully allocated.'
				p = parent
				o = @volume
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "allocated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
				format.html { redirect_to redirect_url }
                format.xml  { render :xml => @volume, :status => :created, :location => @volume }
                format.js
            else
                @error_message ||= @volume.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end

	def destroy
		@volume = parent.volumes.find(params[:id])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		respond_to do |format|
            if @volume.delete!
                flash[:notice] = 'Volume was successfully deleted.'
				p = parent
				o = @volume
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
				format.html { redirect_to redirect_url }
				format.xml  { head :ok }
				format.js
            else
                @error_message ||= @volume.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
				format.js
            end
        end
	end

    def control
        joins = nil
	    conditions = nil
	    @volumes  = CloudVolume.find_all_by_parent(parent, params[:volume_ids], params[:page], joins, conditions, params[:sort], nil, :clusters)
	    
        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        suffix = params[:command_parameter]
        
        @error_message = ''
        @snapshots = []
        if @volumes.size == 0
		    @error_message = "No volumes are specified."
        else
	        @volumes.each do |volume|
				begin
					if params[:command] == 'snapshot'
						snapshot = volume.snapshot!(suffix)
						@snapshots << snapshot if !snapshot.nil? and snapshot.errors.empty?
					end
					volume.delete! if params[:command] == 'destroy'
		            volume.enable! if params[:command] == 'enable'
		            volume.disable! if params[:command] == 'disable'
				rescue
					volume.errors.add(:state, "Failed to #{params[:command]} volume '#{volume.name}': #{$!}")
				end
	            unless volume.errors.empty?
					@error_message += '<br/>' + volume.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
	            end
	            unless snapshot.nil? or snapshot.errors.empty?
					@error_message += '<br/>' + snapshot.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
				@message = "Volumes #{params[:command]}ed." if @error_message.blank?
			end
		end

        @controls_enabled = true
        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
				@volumes.each do |volume|
					p = parent
					o = volume
					auditable_id = volume.destroyed ? nil : o.id
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
				@snapshots.each do |snapshot|
					p = parent
					o = snapshot
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
