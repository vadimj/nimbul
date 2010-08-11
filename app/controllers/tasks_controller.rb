class TasksController < ApplicationController
	before_filter :login_required
	require_role  :admin, :unless => "current_user.has_task_access?(Task.find(params[:id])) "

    def update
        @task = Task.find(params[:id])
        parent = @task.taskable
        parent_type = @task.taskable_type.underscore

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :operations,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)
        
        if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
			respond_to do |format|
	            if @task.update_attributes(params[:task])
	                flash[:notice] = 'Task was successfully updated.'
					o = @task
					parent = o.server
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

	def destroy
        @task = Task.find(params[:id])
        parent = @task.taskable
        parent_type = @task.taskable_type.underscore

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :storage,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

		respond_to do |format|
            if @task.destroy
                flash[:notice] = 'Task was successfully deleted.'
				o = @task
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
                @error_message ||= @task.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
                flash[:error] = @error_message
                format.html { render :action => "new" }
                format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
				format.js
            end
        end
	end

    def run
        @task = Task.find(params[:id])
        parent = @task.taskable
        parent_type = @task.taskable_type.underscore

        @operations = []

        options = {
            :search => params[:search],
            :sort => params[:sort],
            :page => params[:page],
            :anchor => :tasks,
        }
	    redirect_url = send("#{ parent_type }_url", parent, options)

        respond_to do |format|
            if @task.run!
				@operations = @task.new_operations
                flash[:notice] = 'Task ran successfully.'
				o = @task
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
				@error_message = 'There was a problem running this task: '+@task.state_text
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
end
