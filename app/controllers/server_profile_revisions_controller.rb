class ServerProfileRevisionsController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:except => [:index, :list],
		:unless => "params[:id].nil? or current_user.has_server_profile_revision_access?(ServerProfileRevision.find(params[:id])) "

	# GET /server_profile_revisions
	# GET /server_profile_revisions.xml
	# GET /server_profile_revisions.js
	def index
		joins = nil
        conditions = nil
        @server_profile_revisions = ServerProfileRevision.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            format.html
            format.xml  { render :xml => @server_profile_revisions }
            format.js   { render :partial => 'list', :layout => false }
        end
	end
	def list
		index
	end

	# GET /server_profile_revisions/1
	# GET /server_profile_revisions/1.xml
	def show
		@server_profile_revision = ServerProfileRevision.find(params[:id])
		@users = User.find(:all, :order => :login)
        joins = nil
        conditions = [ 'server_profile_revision_id = ?', @server_profile_revision.id ]
        @servers = Server.search(params[:search], params[:page], joins, conditions, params[:sort])

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @server_profile_revision }
		end
	end

    # GET /server_profile_revisions/new
    # GET /server_profile_revisions/new.xml
    def new
		@provider_accounts = provider_accounts_for_user
        @server_profile_revision = ServerProfileRevision.new
        @users = User.find(:all, :order => :login)

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @server_profile_revision }
            format.js
        end
    end

	# GET /server_profile_revisions/1/edit
	# GET /server_profile_revisions/1/edit.json
	def edit
		@provider_accounts = provider_accounts_for_user
		@server_profile_revision = ServerProfileRevision.find(params[:id])
		@users = User.find(:all, :order => :login)
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @server_profile_revision }
		end
	end

    # POST /server_profile_revisions
    # POST /server_profile_revisions.xml
    def create
		@provider_accounts = provider_accounts_for_user
		@provider_account = ProviderAccount.find(params[:provider_account_id]) if params[:provider_account_id]
		if @provider_account
			@server_profile_revision = @provider_account.server_profile_revisions.build(params[:server_profile_revision])
		else
			@server_profile_revision = ServerProfileRevision.new(params[:server_profile_revision])
		end
        
		@users = User.find(:all, :order => :login)
		server_profile_revision_users = [ current_user ]
		if params[:server_profile_revision][:user_ids]
		    server_profile_revision_users = server_profile_revision_users | (User.find(params[:server_profile_revision][:user_ids]))
		end
		@server_profile_revision.users = server_profile_revision_users

        respond_to do |format|
			if @provider_account && !current_user.has_provider_account_access?(@provider_account)
                flash[:error] = "You don't have permisson to add ServerProfileRevisions to #{@provider_account.name}"
                format.html { render :action => "new" }
                format.xml  { render :xml => @server_profile_revision.errors, :status => :unprocessable_entity }
            elsif @server_profile_revision.save
                flash[:notice] = 'Server Profile Revision was successfully created.'
                format.html { redirect_to @server_profile_revision }
                format.xml  { render :xml => @server_profile_revision, :status => :created, :location => @server_profile_revision }
            else
                format.html { render :action => "new" }
                format.xml  { render :xml => @server_profile_revision.errors, :status => :unprocessable_entity }
            end
        end
    end

    # PUT /server_profile_revisions/1
    # PUT /server_profile_revisions/1.xml
    # PUT /server_profile_revisions/1.js
    def update
        @server_profile_revision = ServerProfileRevision.find(params[:id])
        params[:server_profile_revision][:creator_id] = current_user.id
		@users = User.find(:all, :order => :login)
		if params[:server_profile_revision][:user_ids]
            sg_users = (User.find(params[:server_profile_revision][:user_ids]))
            @server_profile_revision.users = (sg_users || [])
        end

        @server = Server.find(params[:server_id]) if params[:server_id]
        if @server.nil?
            redirect_url = @server_profile_revision
        else
            redirect_url = url_for(
                :id => @server.id,
                :controller => 'servers',
                :action => 'show',
                :anchor => 'server_profile')
        end
        
        respond_to do |format|
            if @server_profile_revision.update_attributes(params[:server_profile_revision])
                flash[:notice] = 'Server Profile Revision was successfully updated.'
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js   { render :partial => 'server_profile_revision', :layout => false }
				format.json { render :json => @server_profile_revision }
            else
                flash[:error] = 'There was a problem updating this ServerProfileRevision.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @server_profile_revision.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'server_profile_revision', :layout => false }
				format.json { render :json => @server_profile_revision }
            end
        end
    end
    
  	def auto_complete_for_user_id
	  super
  	end
end
