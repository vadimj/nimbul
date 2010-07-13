class Cluster::DnsHostnamesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

	def setup_data
		@model = @cluster = Cluster.find(params[:cluster_id])
		
		@provider_account = @cluster.provider_account
		
		params[:sort] = params[:sort].nil? ? 'name' : params[:sort].gsub('dns-hostname', 'name') 
		@hostnames  = DnsHostname.find_all_by_cluster_id(@cluster, params[:search], params[:page], nil, nil, params[:sort])
	end
	private :setup_data
	
	# GET /cluster/:cluster_id/dns_hostnames
	def index
		setup_data()
		
        respond_to do |format|
            format.html { render :template => 'dns_hostnames/index' }
            format.xml  { render :xml => @hostnames}
            format.js   { render :template => 'dns_hostnames/index', :layout => false }
        end
	end
	
	def list
		setup_data()
		
        respond_to do |format|
            format.html { render :template => 'dns_hostnames/index' }
            format.xml  { render :xml => @hostnames}
            format.js   { render :partial => 'dns_hostnames/list', :layout => false }
        end
	end

	def show
		@model = @cluster = Cluster.find(params[:cluster_id])
		@provider_account = @cluster.provider_account
		@hostname = DnsHostname.find(params[:id])
		
		respond_to do |format|
			format.html { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname } }
			format.xml { render :xml => @hostname }
			format.js { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname }, :layout => false }
		end
	end

    def acquire
		@model = @cluster = Cluster.find(params[:cluster_id])
		@hostname = DnsHostname.find(params[:id])
		
		@error_messages = []
		
		assignments = if @hostname.nil?
			@cluster.servers.inject([]) { |a,s| a = a | DnsHostnameAssignment.find_all_by_server_id(s); a }
		else
			@cluster.servers.inject([]) { |a,s| a = a | DnsHostnameAssignment.find_all_by_server_id_and_dns_hostname_id(s, @hostname); a }
		end
		
		instances = assignments.inject([]) do |array,assignment|
			array = array | assignment.server.instances.select { |i| not i.has_dns_lease? assignment }; array
		end
		
		instances.each { |i| i.acquire @hostname }

		@leases = DnsLease.find_all_by_cluster_id_and_hostname_id(@model, @hostname)
		@error_message = @error_messages.join("\n<br />")
		
        respond_to do |format|
			if @error_message.blank?
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
				format.xml  { render :xml => @error_messages, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
		@model = @cluster = Cluster.find(params[:cluster_id])
        @hostname = DnsHostname.find(params[:id])        

        if @hostname.nil?
            @error_message = "Couldn't locate Hostname [#{params[:dns_hostname][:id]}]"
        elsif @hostname.has_active_leases? 
            @error_message = "Can not remove hostname '#{@hostname.name}' while it is in use (active leases: #{@hostname.active_leases.size})"
        else
            begin
                @hostname.destroy
                @message = "Deleted '#{@hostname.name}'"
            rescue
                @error_message = "Failed to delete '#{@hostname.name}': #{$!}"
                @hostname.status_message = "Failed to remove: #{$!}"
            end
        end
        
        respond_to do |format|
			if @error_message.blank?
				flash[:notice] = @message
                format.html { redirect_to @model, :anchor => 'dns'  }
                format.xml  { head :ok }
                format.js
			else
                flash[:error] = @error_message
                format.html { redirect_to @model, :anchor => 'dns' }
				format.xml  { render :xml => @hostname.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end
