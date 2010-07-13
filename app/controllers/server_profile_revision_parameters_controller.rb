class ServerProfileRevisionParametersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "params[:server_profile_revision_id].nil? or current_user.has_server_profile_revision_access?(ServerProfileRevision.find(params[:server_profile_revision_id])) "

    # POST /server_profile_revision_parameters
    # POST /server_profile_revision_parameters.xml
    def create
        @server_profile_revision = ServerProfileRevision.find(params[:server_profile_revision_id])
        @server = Server.find(params[:server_id]) if params[:server_id]

        if @server
            redirect_url = url_for(
                    :id => @server.id,
                    :controller => 'servers',
                    :action => 'show',
                    :anchor => 'server_profile')
        else
            redirect_url = url_for(
                    :id => @server_profile_revision.id,
                    :controller => 'server_profile_revisions',
                    :action => 'show',
                    :anchor => 'variables')
        end
        respond_to do |format|
            if @server_profile_revision.update_attributes(params[:server_profile_revision])
                flash[:notice] = 'Server Profile Variables were successfully updated.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server_profile_revision, :status => :updated, :location => @server_profile_revision }
            else
                flash[:error] = "Failed to update Server Profile Variables"
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server_profile_revision.errors, :status => :unprocessable_entity }
            end
        end
    end

    def sort
        params[:server_profile_revision_parameters].each_with_index do |id, index|
            ServerProfileRevisionParameter.update_all(['position=?', index+1], ['id=?', id])
        end
        render :nothing => true
    end
end
