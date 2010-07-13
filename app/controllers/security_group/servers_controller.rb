class SecurityGroup::ServersController < ApplicationController
    before_filter :login_required
    require_role  :admin,
        :unless => "current_user.has_security_group_access?(SecurityGroup.find(params[:security_group_id])) "

    def create
        @security_group = SecurityGroup.find(params[:security_group_id])
        @server = Server.find(params[:server][:id])

        if @server.nil?
            @error_message = "Couldn't locate Server [#{params[:server][:id]}]"
        elsif @security_group.servers.include?(@server)
            @error_message = "Server '#{@server.name}' is already included in #{@security_group.name}"
        else
            begin
                Ec2Adapter.add_security_group_server(@security_group, @server)
                @message = "Added '#{@server.name}' to #{@security_group.name}"
            rescue
                @error_message = "Failed to add '#{@server.name}': #{$!}"
            end
        end

        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @security_group }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @security_group }
				format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
				format.js
			end
	    end
    end

    def destroy
        @security_group = SecurityGroup.find(params[:security_group_id])
        @server = Server.find(params[:id])        

        if @server.nil?
            @error_message = "Couldn't locate Server [#{params[:server][:id]}]"
        elsif !@security_group.servers.include?(@server)
            @error_message = "Server '#{@server.name}' is not in #{@security_group.name}"
        else
            begin
                Ec2Adapter.remove_security_group_server(@security_group, @server)
                @message = "Remove '#{@server.name}' from #{@security_group.name}"
            rescue
                @error_message = "Failed to remove '#{@server.name}': #{$!}"
                @server.status_message = "Failed to remove: #{$!}"
            end
        end

        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @security_group }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @security_group }
				format.xml  { render :xml => @security_group.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end

