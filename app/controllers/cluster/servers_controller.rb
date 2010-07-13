class Cluster::ServersController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

    def index
		@cluster = Cluster.find(params[:cluster_id])
		@provider_account = @cluster.provider_account
		
		joins = nil
		conditions = [ 'cluster_id = ?', @cluster.id ]
        @servers = Server.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @servers }
            format.js   { render :partial => 'servers/list', :layout => false }
        end
	end
	def list
		index
	end

	def new
		@cluster = Cluster.find(params[:cluster_id]) if params[:cluster_id]
        @provider_account = ProviderAccount.find(@cluster.provider_account_id, :include => [ :clusters, :server_profiles ])
		
        @instance = Instance.find(params[:instance_id]) if params[:instance_id]

		@server = Server.new
        @server.key_name = @provider_account.default_main_key unless @provider_account.default_main_key.blank?
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @server }
		end
	end

    def destroy
        @cluster = Cluster.find(params[:cluster_id])
        @server = Server.find(params[:id])        

        respond_to do |format|
			if !@server.nil? and @cluster.servers.delete(@server)
				flash[:notice] = "Server '#{@server.name}' has been deleted."
                format.html { redirect_to @cluster }
                format.xml  { head :ok }
                format.js
			else
				flash[:notice] = "Failed to delete Server '#{@server.name}'."
				format.html { render :action => "edit" }
				format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

	def control 
		@cluster = Cluster.find(params[:cluster_id])
        @message = ''
        @servers = []
        @instances = []
        if params[:command] == 'start'
            if params[:server_ids].nil?
                @success = false
                @message = "Didn't find any servers to start"
            else
		        count = 1
    		    if params[:instance_start_count]
	    	        count = params[:instance_start_count].to_i
		            count = 10 if count > 10
    		    end

    		    dns_active = (params[:skip_dns_leases][0].to_i == 1 rescue false) ? false : true
    		    
    		    @servers = (Server.find(params[:server_ids]))
                if @servers.size == 0
                    @success = false
                    @message = "Didn't find any servers to start"
                else
                    @success = true
                    p = {
                        :count => count,
                        :user_id => current_user.id,
                        :dns_active => dns_active,
                    }
		            @servers.each do |s|
			    	    if current_user.has_server_access?(s)
			                if s.start(p)
    			                s.status_message = "Starting #{count} instance(s)."
                            else
                                @success = false
                                @message += " Failed to start '#{s.name}': #{s.status_message}"
                            end
			    	    else
				    	    s.status_message = "You don't have permissions to start '#{s.name}'."
                            @success = false
                            @message += " You don't have permissions to start '#{s.name}'."
    			    	end
                    end
		        end
            end
        end
        unless params[:instance_command].blank?
            InstancesController.control_instances(current_user, params) do |instances, success, message|
                @instances = instances
                @success = success
                @message = message
            end
		end
	
		redirect_url = cluster_path(@cluster)
	
	    respond_to do |format|
            if @success
    			flash[:notice] = 'Success.'
	            format.html { redirect_to redirect_url }
	            format.xml  { head :ok }
	            format.js
            else
    			flash[:error] = @message
	            format.html { redirect_to redirect_url }
				format.xml  { render :xml => @servers, :status => :unprocessable_entity }
	            format.js
            end
	    end
	end
end

