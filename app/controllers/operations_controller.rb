class OperationsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_server_access?(Server.find(params[:server_id])) "

	# GET /operations
	# GET /operations.xml
	# GET /operations.js
	# GET /servers/1/operations
	# GET /servers/1/operations.xml
	# GET /servers/1/operations.js
	def index
        @server = Server.find(params[:server_id])
		joins = 'INNER JOIN instances ON instances.id = operations.instance_id'
		conditions = [ 'instances.server_id = ?', @server.id ]
        params[:sort] = 'created_at_reverse' if params[:sort].blank?
        @operations = Operation.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            if @operations
                format.html
                format.xml  { render :xml => @operations }
                format.js   { render :partial => 'operations/list', :layout => false }
            else
                flash[:error] = @error_message
                format.html { redirect_to :back }
                format.xml  { render :xml => @operation.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'shared/error', :layout => false }
            end
        end
	end
	def list
		index
	end

    def show
        @server = Server.find(params[:server_id])
        @operation = Operation.find(params[:id], :include => :operation_logs)
        @operation_logs = @operation.operation_logs

        respond_to do |format|
            format.html
            format.xml { render :xml => @operation_logs }
            format.js
        end
    end
end
