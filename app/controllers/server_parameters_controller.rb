class ServerParametersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "params[:server_id].nil? or current_user.has_server_access?(Server.find(params[:server_id])) "

    # POST /server_parameters
    # POST /server_parameters.xml
    def create
        @server = Server.find(params[:server_id])
        redirect_url = url_for(
                    :id => @server.id,
                    :controller => 'servers',
                    :action => 'show',
                    :anchor => 'variables')
        respond_to do |format|
            if @server.update_attributes(params[:server])
                flash[:notice] = 'Server Variables were successfully updated.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server, :status => :updated, :location => @server }
            else
                flash[:error] = "Failed to update Server Variables"
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
            end
        end
    end

    def sort
        params[:server_parameters].each_with_index do |id, index|
            ServerParameter.update_all(['position=?', index+1], ['id=?', id])
        end
        render :nothing => true
    end
end
