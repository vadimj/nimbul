class ClustersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:except => [:index, :list],
		:unless => "params[:id].nil? or current_user.has_cluster_access?(Cluster.find(params[:id])) "

	# GET /clusters
	# GET /clusters.xml
	# GET /clusters.js
	def index
        @clusters = Cluster.find_all_by_user(current_user)

        respond_to do |format|
            format.html
            format.xml  { render :xml => @clusters }
            format.js   { render :partial => 'list', :layout => false }
        end
	end
	def list
		index
	end

	# GET /clusters/1
	# GET /clusters/1.xml
	def show
		@cluster = Cluster.find(params[:id], :include => :cluster_parameters)
		@provider_account = ProviderAccount.find(@cluster.provider_account_id, :include => :provider_account_parameters)
		@users = User.find(:all, :order => :login)
		
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @cluster }
		end
	end

    # GET /clusters/new
    # GET /clusters/new.xml
    def new
		@provider_accounts = provider_accounts_for_user
        @cluster = Cluster.new
        @cluster.provider_account_id = params[:provider_account_id] if params[:provider_account_id]
        @users = User.find(:all, :order => :login)

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @cluster }
            format.js
        end
    end

	# GET /clusters/1/edit
	# GET /clusters/1/edit.json
	def edit
		@provider_accounts = provider_accounts_for_user
		@cluster = Cluster.find(params[:id])
		@users = User.find(:all, :order => :login)
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @cluster }
		end
	end

    # POST /clusters
    # POST /clusters.xml
    def create
        if params[:cancel_button]
            redirect_back_or_default(clusters_path)
        else
			cluster_params = params[:cluster]
			provider_account_id = cluster_params[:provider_account_id] || params[:provider_account_id]
			
			@provider_accounts = provider_accounts_for_user
			@provider_account = @provider_accounts.detect{ |a| a.id == provider_account_id }
			
			if @provider_account
				@cluster = @provider_account.clusters.build(cluster_params)
			else
				@cluster = Cluster.new(cluster_params)
			end
        
			respond_to do |format|
				if @provider_account && !current_user.has_provider_account_access?(@provider_account)
			        flash[:error] = "You don't have permisson to add Clusters to this provider account"
			        format.html { render :action => "new" }
			        format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
			    elsif @cluster.save
					pa = @cluster.provider_account
					c = @cluster
					o = @cluster
					AuditLog.create(
						:provider_account_name => pa.name,
						:provider_account_id => pa.id,
						:cluster_name => c.name,
						:cluster_id => c.id,
						:auditable_id => o.id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "created '#{o.name}'",
						:changes => o.tracked_changes,
						:force => true
					)
					flash[:notice] = "Added Cluster '#{@cluster.name}'."
			        format.html { redirect_to @cluster }
			        format.xml  { render :xml => @cluster, :status => :created, :location => @cluster }
			    else
			        format.html { render :action => "new" }
			        format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
			    end
			end
        end
    end

    # PUT /clusters/1
    # PUT /clusters/1.xml
    # PUT /clusters/1.js
    def update
        @cluster = Cluster.find(params[:id], :include => [ :provider_account ] )
        if params[:cancel_button]
            redirect_back_or_default(@cluster)
        else
			@users = User.find(:all, :order => :login)
			if params[:cluster][:user_ids]
			    sg_users = (User.find(params[:cluster][:user_ids]))
			    @cluster.users = (sg_users || [])
			end
        
			respond_to do |format|
			    if @cluster.update_attributes(params[:cluster])
					pa = @cluster.provider_account
					c = @cluster
					o = @cluster
					AuditLog.create(
						:provider_account_name => pa.name,
						:provider_account_id => pa.id,
						:cluster_name => c.name,
						:cluster_id => c.id,
						:auditable_id => o.id,
						:auditable_type => o.class.to_s,
						:auditable_name => o.name,
						:author_login => current_user.login,
						:author_id => current_user.id,
						:summary => "updated '#{o.name}'",
						:changes => o.tracked_changes,
						:force => false
					)
			        flash[:notice] = 'Cluster was successfully updated.'
			        format.html { redirect_to @cluster }
			        format.xml  { head :ok }
			        format.js   { render :partial => 'cluster', :layout => false }
					format.json { render :json => @cluster }
			    else
			        flash[:error] = 'There was a problem updating this Cluster.'
			        format.html { render :action => "edit" }
			        format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
			        format.js   { render :partial => 'cluster', :layout => false }
					format.json { render :json => @cluster }
			    end
			end
        end
    end
    
    def destroy
        @cluster = Cluster.find(params[:id], :include => [ :provider_account ])
        @provider_account = @cluster.provider_account

        respond_to do |format|
			if !current_user.has_provider_account_access?(@provider_account)
				@message = "You don't have permisson to delete clusters from #{@provider_account.name}"
                flash[:error] = message
                format.html { redirect_to clusters_path }
                format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
                format.js
            elsif @cluster.destroy
                flash[:notice] = "Deleted cluster '#{@cluster.name}'."
				p = @provider_account
				o = @cluster
				AuditLog.create_for_parent(
					:parent => p,
					:auditable_id => nil,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "deleted '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
                format.html { redirect_to clusters_path }
                format.xml  { render :xml => @cluster, :status => :created, :location => @cluster }
                format.js
			else
				@error_messages = @cluster.errors.collect{ |attr,msg|  "#{attr} - #{msg}" }
                format.html { redirect_to clusters_path }
                format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
    
  	def auto_complete_for_user_id
		super
  	end
end
