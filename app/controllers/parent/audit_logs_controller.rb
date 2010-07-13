class Parent::AuditLogsController < ApplicationController
    parent_resources :author
    before_filter :login_required
    require_role  :admin, :unless => "parent.nil? || current_user.has_access?(parent)"

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
		
		@parent_type = parent_type || 'author'
		@parent = parent || current_user
		
		# special case for authors
		if @parent_type == 'author'
			@author ||= @parent
			@audit_logs  = AuditLog.search_by_author(@parent, options)
		else
			@audit_logs  = AuditLog.search_by_parent(@parent, options)
		end
		
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
