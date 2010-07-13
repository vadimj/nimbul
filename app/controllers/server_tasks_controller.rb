class ServerTasksController < ApplicationController
	before_filter :login_required
	require_role  :admin, :unless => "current_user.has_server_task_access?(ServerTask.find(params[:id])) "

    def update
        @server_task = ServerTask.find(params[:id])
        @server = @server_task.server
        
        parent_type = 'server'
        parent = @server

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
	            if @server_task.update_attributes(params[:server_task])
	                flash[:notice] = 'Task was successfully updated.'
					o = @server_task
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
end
