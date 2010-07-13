class Server::SecurityGroupsController < ApplicationController
    before_filter :login_required
    require_role  :admin,
        :unless => "params[:server_id].nil? or current_user.has_server_access?(Server.find(params[:server_id])) "

    def create
        @server = Server.find(params[:server_id])
        begin
            @security_group = SecurityGroup.find(params[:security_group][:id])
            @included = @server.security_groups.include?(@security_group)
        rescue
            @error = "Couldn't find a security_group with id: #{params[:security_group][:id]}."
            flash[:error] = @error
        end

        respond_to do |format|
			if !@security_group.nil? and (@included or (@server.security_groups << @security_group))
				flash[:notice] = "Added Server to #{@security_group.name}."
                format.html { redirect_to @server }
                format.xml  { head :ok }
                format.js
			else
                format.html { redirect_to @server }
				format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
        @server = Server.find(params[:server_id])
        @security_group = SecurityGroup.find(params[:id])        

        respond_to do |format|
			if !@security_group.nil? and @server.security_groups.delete(@security_group)
				flash[:notice] = "Removed Server from #{@security_group.name}."
                format.html { redirect_to @server }
                format.xml  { head :ok }
                format.js
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end

