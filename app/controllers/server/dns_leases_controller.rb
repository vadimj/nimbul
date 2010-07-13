class Server::DnsLeasesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_server_access?(Server.find(params[:server_id]))"

	# GET /server/:id/dns_leases
	def index
		@model = @server = Server.find(params[:server_id])
		@hostname = params[:dns_hostname_id] ? DnsHostname.find(params[:dns_hostname_id]) : nil
		@leases = DnsLease.find_all_by_server_id_and_hostname_id(@server, @hostname)
		
        respond_to do |format|
            format.html { render :template => 'dns_leases/index' }
            format.xml  { render :xml => @leases }
            format.js   { render :template => 'dns_leases/index', :layout => false }
        end
	end
	
	def list
		index
	end
	
	def show
		@model = @server = Server.find(params[:server_id])
		@hostname = params[:dns_hostname_id] ? DnsHostname.find(params[:dns_hostname_id]) : nil
		@lease = DnsLease.find(@hostname)
		
        respond_to do |format|
            format.html { render :partial => 'dns_leases/lease_row', :locals => { :lease => @lease} }
            format.xml  { render :xml => @lease }
            format.js   { render :partial => 'dns_leases/lease_row', :locals => { :lease => @lease}, :layout => false }
        end
	end
	
	# DELETE /servers/:server_id/dns_hostnames/:dns_hostname_id/dns_leases/release
	def release
		@model = @server = Server.find(params[:server_id])
		@hostname = params[:dns_hostname_id] ? DnsHostname.find(params[:dns_hostname_id]) : nil
		@leases = DnsLease.find_all_by_server_id_and_hostname_id(@server, @hostname)
		
		@leases.each { |l| l.release }; 
		
        respond_to do |format|
            format.html { head :ok }
            format.js 
        end
	end
end
