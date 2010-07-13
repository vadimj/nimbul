class DnsHostnamesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "params[:id] and current_user.has_dns_hostname_access?(DnsHostname.find(params[:id]))"

	#  POST   /instances/:instance_id/dns_hostnames/acquire
	#  POST   /instances/:instance_id/dns_hostnames/:id/acquire
	def acquire
		@instance = Instance.find(params[:instance_id])
		@instance.acquire( params[:id] ? DnsHostname.find(params[:id]) : nil )
		
		respond_to do |format|
			format.js
		end
	end
	
	def show
		@hostname = DnsHostname.find(params[:id])
		
		respond_to do |format|
			format.json { render :json => @hostname }
		end
	end
	
	def update
		@hostname = DnsHostname.find(params[:id])
		new_name = params[:dns_hostname][:name].gsub(/\s/, '') rescue nil
		
		@check = DnsHostname.find_by_name_and_provider_account_id(new_name, @hostname.provider_account)
		if @check.nil?
			@hostname.update_attribute(:name, new_name) unless new_name.blank?
		end
		
		respond_to do |format|
			format.json { render :json => @hostname }
		end
	end
end
