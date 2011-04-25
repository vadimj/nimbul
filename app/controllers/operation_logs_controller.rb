class OperationLogsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "current_user.has_server_access?(Operation.find(params[:operation_id]).server) "

	def index
        @operation = Operation.find(params[:operation_id])
        @server = @operation.server
        @operation_logs = @operation.operation_logs

        respond_to do |format|
            if @operation_logs
                format.html
                format.xml  { render :xml => @operation_logs }
            else
                flash[:error] = "Failed to find Logs for this Operation"
                format.html { redirect_to :back }
                format.xml  { render :xml => @operation.errors, :status => :unprocessable_entity }
            end
        end
	end
end
