class Server::ServerResourcesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_cluster_access?(Server.find(params[:server_id]).cluster) "

	def new
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @server_resource = ServerResource.new
        
		respond_to do |format|
			format.html
			format.xml  { render :xml => @server_resource }
			format.js
		end
    end		

    def create
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
		@server_resource = @server.server_resources.build(params[:server_resource])

        # check on the availability of the cloud resource
        if params[:cloud_resource_id]
			@cloud_resource = CloudResource.find(params[:cloud_resource_id])
			if @cloud_resource.nil?
				@error_message = "Couldn't find cloud resource with id [#{params[:cloud_resource_id]}]."
			elsif !@cluster.cloud_resources.include?(@cloud_resource)
				@error_message = "'#{@cloud_resource.name}' is not available for cluster '#{@cluster.name}'."
			end
		end

        respond_to do |format|
			if @error_message.blank? and @server_resource.save
				@message = "Added resource to #{@server.name}"
				flash[:notice] = @message
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
				format.xml  { render :xml => @server_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
    def update
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @server_resource = @server.server_resources.find(params[:id])

        # check on the availability of the cloud resource
        if params[:cloud_resource_id]
			@cloud_resource = CloudResource.find(params[:cloud_resource_id])
			if @cloud_resource.nil?
				@error_message = "Couldn't find cloud resource with id [#{params[:cloud_resource_id]}]."
			elsif !@cluster.cloud_resources.include?(@cloud_resource)
				@error_message = "'#{@cloud_resource.name}' is not available for cluster '#{@cluster.name}'."
			end
		end
        
        respond_to do |format|
			if @error_message.blank? and @server_resource.update_attributes(params[:server_resource])
				@message = "Updated resource for #{@server.name}"
				flash[:notice] = @message
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message ||= @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
                flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
				format.xml  { render :xml => @server_resource.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
        @server = Server.find(params[:server_id])
        @cluster = @server.cluster
        @server_resource = @server.server_resources.find(params[:id])
        
        respond_to do |format|
			if @server_resource.destroy
				flash[:notice] = "Removed #{@server_resource.cloud_resource.name} from #{@server.name}."
                format.html { redirect_to @server, :anchor => params[:anchor] }
                format.xml  { head :ok }
                format.js
			else
				@error_message = @server_resource.errors.collect{ |attr,msg| attr.humanize + ' - ' + msg}.join('<br/>')
				flash[:error] = @error_message
                format.html { redirect_to @server, :anchor => params[:anchor] }
 				format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end
    
end

