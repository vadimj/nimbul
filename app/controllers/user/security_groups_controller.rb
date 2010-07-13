class User::SecurityGroupsController < ApplicationController
	before_filter :login_required
	# GET /security_groups
	# GET /security_groups.xml
	# GET /security_groups.js
	# GET /provider_accounts/1/security_groups
	# GET /provider_accounts/1/security_groups.xml
	# GET /provider_accounts/1/security_groups.js
	def index
		unless params[:provider_account_id].blank?
	    	@provider_account = ProviderAccount.find(params[:provider_account_id])
		end

		if @provider_account
			#
			# get corresponding security_groups
			#
			joins = nil
			security_group_conditions = [ 'provider_account_id = ?', @provider_account.id ]
        	@security_groups = SecurityGroup.search(params[:search], params[:page], joins, security_group_conditions, params[:sort])

	        respond_to do |format|
    	        format.html # index.html.erb
        	    format.xml  { render :xml => @security_groups }
            	format.js   { render :partial => 'security_groups/list', :layout => false }
	        end
		else
			respond_to do |format|
				format.js	{ render :nothing => true }
			end
		end
	end
	def list
		index
	end
end
