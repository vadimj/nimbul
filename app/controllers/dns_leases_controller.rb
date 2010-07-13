class DnsLeasesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_dns_lease_access?(DnsLease.find(params[:id]))"

    # DELETE /dns_leases/:id/release
    def release
		@lease = DnsLease.find(params[:id])
		@lease.release
		
		respond_to do |format|
			format.js # release.js.rjs
		end
	end
end
