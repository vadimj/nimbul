class Parent::TasksController < ApplicationController
    parent_resources :server
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_access?(parent)"

    def index
	    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

        joins = nil
	    conditions = nil
	    @tasks  = Task.search_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter])

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
        @task = Task.new
        @operation_type = params[:class_type] unless params[:class_type].blank?
        @operation = Operation.factory(@operation_type)
        @task.operation = @operation.type

        respond_to do |format|
            format.html
            format.xml  { render :xml => @task }
            format.js
        end
    end

    def create
        @task = parent.tasks.build(params[:task])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			respond_to do |format|
	            if @task.save
	                flash[:notice] = 'Server task was successfully created.'
					o = @task
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
	                format.xml  { render :xml => @task, :status => :created, :location => @task }
	                format.js
	            else
	                @error_message ||= @task.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
	                flash[:error] = @error_message
	                format.html { render :action => "new" }
	                format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
	                format.js
	            end
	        end
        end
    end

    def edit
        @task = Task.find(params[:id])

        respond_to do |format|
            format.html
            format.json { render :json => @task }
        end
    end

    def update
        @task = Task.find(params[:id])

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)
        
        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			respond_to do |format|
	            if @task.update_attributes(params[:task])
	                flash[:notice] = 'Task was successfully updated.'
					o = @task
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
	                format.json { render :json => @task }
	            else
	                flash[:error] = 'There was a problem updating this task.'
	                format.html { render :action => "edit" }
	                format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
	                format.js
	                format.json { render :json => @task }
	            end
	        end
        end
    end
end
