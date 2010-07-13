class Server::InstancesController < ApplicationController
	before_filter :login_required
	require_role  :admin,
        :unless => "current_user.has_server_access?(Server.find(params[:server_id])) "

    def index
        @server = Server.find(params[:server_id])

        joins = nil
	    conditions = nil
	    @instances  = Instance.find_all_by_server(@server, params[:search], params[:page], joins, conditions, params[:sort])

	    @skip_server_column = true
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @instances }
	        format.js
	    end
    end
    def list
        index
    end
end
