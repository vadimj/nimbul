class Instance::DnsHostnamesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_instance_access?(Instance.find(params[:instance_id])) "

	#  POST   /instances/:instance_id/dns_hostnames/acquire
	#  POST   /instances/:instance_id/dns_hostnames/:id/acquire
	def acquire
		@instance = Instance.find(params[:instance_id])
		@instance.acquire( params[:id] ? DnsHostname.find(params[:id]) : nil )

		@instance.dns_leases(true) # and then reload our leases
		
		head :ok		
	end

	# GET /instances/:instance_id/dns_hostnames	
	def show
		@instance = Instance.find(params[:instance_id])
		respond_to do |format|
			format.js 
		end
	end
end
