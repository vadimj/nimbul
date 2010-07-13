class SystemLogsController < ApplicationController
    before_filter :login_required

    def index
		params[:sort] ||= 'created_at_reverse'
		
		options = {
			:search => params[:search],
			:page => params[:page],
	        :joins => nil,
		    :conditions => nil,
		    :order => params[:sort],
		    :filter => params[:filter],
		    :include => [ :provider_account, :cluster, :auditable, :author ],
		}
		
		@audit_logs  = AuditLog.search_by_user(current_user, options)
        
	    respond_to do |format|
	        format.html
	        format.xml  { render :xml => @audit_logs }
	        format.js
	    end
    end
    def list
        index
    end
end
