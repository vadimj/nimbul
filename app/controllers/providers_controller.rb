class ProvidersController < ApplicationController
	before_filter :login_required
	require_role  :admin
	
	def index
        @providers = Provider.find(:all)

	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @providers }
	        format.js
	    end
	end
end
