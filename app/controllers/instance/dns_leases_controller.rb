class Instance::DnsLeasesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_instance_access?(Instance.find(params[:instance_id]))"

	# DELETE /instances/:instance_id/dns_leases/release
    # DELETE /instances/:instance_id/dns_leases/:id/release
    def release
		@instance = Instance.find(params[:instance_id])
		leases = (params[:id] ? DnsLease.find_all_by_id(params[:id]) : @instance.dns_leases)
		leases.each { |l| l.release }
		leases.each { |l| l.reload } # and then force a reload so we have fresh data
		
		head :ok
	end

	# GET /instances/:instance_id/dns_leases
	def show
		@instance = Instance.find(params[:instance_id])
		
		respond_to do |format|
			format.js 
		end
	end
end
