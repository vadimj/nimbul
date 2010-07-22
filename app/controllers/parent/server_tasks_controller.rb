class Parent::ServerTasksController < ApplicationController
    parent_resources :server
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @server_tasks  = ServerTask.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter])

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
    
    def new
        @server_task = ServerTask.new
        @operation_type = 'Operation::'+params[:class_type] unless params[:class_type].blank?
        @operation = Operation.factory(@operation_type)
        @server_task.operation = @operation.type

        respond_to do |format|
            format.html
            format.xml  { render :xml => @server_task }
            format.js
        end
    end

    def create
        @server_task = parent.server_tasks.build(params[:server_task])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :server_tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			respond_to do |format|
	            if @server_task.save
	                flash[:notice] = 'Server task was successfully created.'
					o = @server_task
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
					format.html { redirect_to redirect_url }
	                format.xml  { render :xml => @server_task, :status => :created, :location => @server_task }
	                format.js
	            else
	                @error_message ||= @server_task.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
	                flash[:error] = @error_message
	                format.html { render :action => "new" }
	                format.xml  { render :xml => @server_task.errors, :status => :unprocessable_entity }
	                format.js
	            end
	        end
        end
    end

    def edit
        @server_task = ServerTask.find(params[:id])

        respond_to do |format|
            format.html
            format.json { render :json => @server_task }
        end
    end

    def update
        @server_task = ServerTask.find(params[:id])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :server_tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)
        
        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			respond_to do |format|
	            if @server_task.update_attributes(params[:server_task])
	                flash[:notice] = 'Task was successfully updated.'
					o = @server_task
					AuditLog.create_for_parent(
						:parent => parent,
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
	                format.js
	                format.json { render :json => @server_task }
	            else
	                flash[:error] = 'There was a problem updating this task.'
	                format.html { render :action => "edit" }
	                format.xml  { render :xml => @server_task.errors, :status => :unprocessable_entity }
	                format.js
	                format.json { render :json => @server_task }
	            end
	        end
        end
    end

	def destroy
		@server_task = parent.server_tasks.find(params[:id])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		respond_to do |format|
            if @server_task.destroy
                flash[:notice] = 'Task was successfully deleted.'
				o = @server_task
				AuditLog.create_for_parent(
					:parent => parent,
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
                @error_message ||= @server_task.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @server_task.errors, :status => :unprocessable_entity }
				format.js
            end
        end
	end

    def run
        @server_task = ServerTask.find(params[:id])
        @operations = []

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :server_tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        respond_to do |format|
            if @server_task.run!
				@operations = @server_task.new_operations
                flash[:notice] = 'Task ran successfully.'
				o = @server_task
				AuditLog.create_for_parent(
					:parent => parent,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "ran '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
				@error_message = 'There was a problem running this task: '+@server_task.state_text
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server_task.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end
