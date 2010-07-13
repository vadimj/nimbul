class EventsController < ApplicationController
    before_filter :login_required

	# GET /events
	# GET /events.xml
	def index
		@provider_accounts = ProviderAccount.find(:all, :include => [ :security_groups ], :order => :name)

		if params[:server_id]
			@server = Server.find(params[:server_id], :include => [ :security_groups ])
			@provider_account = @server.provider_account
			@security_group = @server.security_groups.first
		end
		
		if params[:security_group_id]
			@security_group = SecurityGroup.find(params[:security_group_id])
			@provider_account = @security_group.provider_account
		elsif params[:provider_account_id]
			@provider_account = ProviderAccount.find(params[:provider_account_id], :include => [ :security_groups ])
		end

		if @provider_account
			@security_groups = @provider_account.security_groups
		end

		conditions = nil
		if @server
			conditions = [ 'server_id=?', @server.id ]
		elsif @security_group
			conditions = [ 'security_group_id=?', @security_group.id ]
		elsif @provider_account
			conditions = [ 'provider_account_id=?', @provider_account.id ]
		end

		joins = nil
		params[:sort] ||= 'created_at_reverse'
		@events = Event.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @events }
            format.js   { render :partial => 'events/list', :layout => false }
        end
    end
    def list
        index
    end

	# GET /events/1
	# GET /events/1.xml
	def show
		@event = Event.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.xml	{ render :xml => @event }
		end
	end
end
