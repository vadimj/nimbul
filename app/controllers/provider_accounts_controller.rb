class ProviderAccountsController < ApplicationController
    before_filter :login_required
    require_role  :admin,
        :except => [ :control ],
	    :unless => "params[:id].nil? or current_user.has_provider_account_access?(ProviderAccount.find(params[:id])) "
        
	# GET /user/provider_accounts
	# GET /user/provider_accounts.xml
	# GET /user/provider_accounts.js
	def index
		options = {
			:search => params[:search],
			:page => params[:page],
			:order => params[:sort],
			:filter => params[:filter]
		}
		@provider_accounts = ProviderAccount.search_by_user(current_user, options)

        respond_to do |format|
            format.html # index.html.erb
        	format.xml  { render :xml => @provider_accounts }
        	format.js   { render :partial => 'provider_accounts/list', :layout => false }
        end
	end
	def list
        index
	end

	# POST /provider_accounts/1
	# POST /provider_accounts/1.xml
	# POST /provider_accounts/1.js
	def show
		@provider_account = ProviderAccount.find(params[:id])
		if params[:refresh]
			@provider_account.refresh
		end
		joins = nil
		conditions = [ 'provider_account_id = ?', @provider_account.id ]
		@instances = Instance.search(params[:search], params[:page], joins, conditions, params[:sort])
		@users = User.find(:all, :order => :login)

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @provider_account }
			format.json  { render :json => @provider_account }
		end
	end

	# GET /provider_accounts/new
	# GET /provider_accounts/new.xml
	def new
		@provider_account = ProviderAccount.new
		@users = User.find(:all, :order => :login)

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @provider_account }
		end
	end

	# GET /provider_accounts/1/edit
	def edit
		@provider_account = ProviderAccount.find(params[:id])
		@users = User.find(:all, :order => :login)
		@provider_account.publishers.build({
			:type => 'S3Publisher',
			:state => 'pending',
		})
	end

	# POST /provider_accounts
	# POST /provider_accounts.xml
	def create
            if params[:cancel_button] 
                redirect_back_or_default(provider_accounts_path)
            else
		@provider_account = ProviderAccount.new(params[:provider_account])
		@provider_account.users = [ current_user ]

		respond_to do |format|
			if @provider_account.save
				o = @provider_account
				AuditLog.create(
					:provider_account_name => o.name,
					:provider_account_id => o.id,
					:cluster_name => nil,
					:cluster_id => nil,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "created '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
				flash[:notice] = 'Account was successfully created, it can take up to 2 minutes for the initial refresh.'
				format.html { redirect_to @provider_account }
				format.xml  { render :xml => @provider_account, :status => :created, :location => @provider_account }
			else
				flash[:error] = 'Failed to Create an Account'
				format.html { render :action => "new" }
				format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
			end
		end
            end
	end

	# PUT /provider_accounts/1
	# PUT /provider_accounts/1.xml
	def update
	    @provider_account = ProviderAccount.find(params[:id])
            if params[:cancel_button] 
                redirect_back_or_default(@provider_account)
            else
		@users = User.find(:all, :order => :login)
		if params[:provider_account][:user_ids]
			account_users = [current_user] | (User.find(params[:provider_account][:user_ids]))
			@provider_account.users = (account_users || [])
		end
		
		redirect_url = provider_account_url(@provider_account, :anchor => params[:anchor])

		respond_to do |format|
			if @provider_account.update_attributes(params[:provider_account])
				flash[:notice] = 'Provider Account was successfully updated.'
				o = @provider_account
				AuditLog.create(
					:provider_account_name => o.name,
					:provider_account_id => o.id,
					:cluster_name => nil,
					:cluster_id => nil,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "updated '#{o.name}'",
					:changes => o.tracked_changes,
					:force => false
				)
				format.html { redirect_to redirect_url }
				format.xml  { head :ok }
				format.json { render :json => @provider_account }
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
				format.json { render :json => @provider_account }
			end
		end
            end
	end

	#def update_all		
	#	attributes = params[:user]
	#	provider_account_attributes = attributes[:provider_account_attributes]
	#	provider_account_attributes.each do |a|
	#		# setting attributes
	#		if a[:id].blank?
	#			provider_account = current_user.provider_accounts.build(a)
	#		else
	#			provider_account = ProviderAccount.find(a[:id])
	#			if provider_account and current_user.has_provider_account_access?(provider_account)
	#				provider_account.attributes = a
	#			end
	#		end
	#		# now persisting
	#		if provider_account.should_destroy?
	#			msg = {
	#				:provider_account_id => provider_account.id,
	#				:provider_account_name => provider_account.name,
	#				:user_id => current_user.id,
	#				:user_login => current_user.login,
	#				:subject => current_user.login_and_name,
	#				:action => 'destroy',
	#				:object => provider_account.name,
	#				:description => "User #{current_user.login} deleted #{provider_account.class.name} '#{provider_account.name}'",
	#			}
	#			provider_account.destroy
	#			Event.log(msg)
	#		else
	#			msg = {
	#				:provider_account_id => provider_account.id,
	#				:provider_account_name => provider_account.name,
	#				:user_id => current_user.id,
	#				:user_login => current_user.login,
	#				:subject => current_user.login_and_name,
	#				:action => 'update',
	#				:object => provider_account.name,
	#				:description => "User #{current_user.login} updated #{provider_account.class.name} '#{provider_account.name}'",
	#			}
	#			provider_account.save(false)
	#			Event.log(msg)
	#		end
	#	end
	#
	#	flash[:notice] = 'Provider Account(s) were successfully updated.'
	#	if params[:destroy]
	#		flash[:notice] = 'Provider Account(s) were successfully deleted.'
	#	end
	#	respond_to do |format|
	#		format.html { redirect_to provider_accounts_path }
	#		format.xml  { head :ok }
	#	end
	#end

	# DELETE /provider_accounts/1
	# DELETE /provider_accounts/1.xml
	def destroy
		@provider_account = ProviderAccount.find(params[:id])
		if @provider_account.destroy
				o = @provider_account
				AuditLog.create(
					:provider_account_name => o.name,
					:provider_account_id => nil,
					:cluster_name => nil,
					:cluster_id => nil,
					:auditable_id => o.id,
					:auditable_type => o.class.to_s,
					:auditable_name => o.name,
					:author_login => current_user.login,
					:author_id => current_user.id,
					:summary => "deleted '#{o.name}'",
					:changes => o.tracked_changes,
					:force => true
				)
		end

		respond_to do |format|
			format.html { redirect_to(provider_accounts_url) }
			format.xml  { head :ok }
		end
	end

    def control
        @provider_accounts = (ProviderAccount.find(params[:provider_account_ids]))

        @error_message = ''
        if @provider_accounts.size == 0
		    @error_message = "No Accounts to update."
        else
		    @provider_accounts.each do |a|
				if current_user.has_provider_account_access?(a) and (params[:command] == 'destroy') and
					begin
						if a.destroy
							o = a
							AuditLog.create(
								:provider_account_name => o.name,
								:provider_account_id => nil,
								:cluster_name => nil,
								:cluster_id => nil,
								:auditable_id => o.id,
								:auditable_type => o.class.to_s,
								:auditable_name => o.name,
								:author_login => current_user.login,
								:author_id => current_user.id,
								:summary => "deleted '#{o.name}'",
								:changes => o.tracked_changes,
								:force => true
							)
						end
					rescue Exception => e
						msg = "failed to delete account: #{e.message}"
						a.errors.add(:id, msg)
						Rails.logger.error("#{msg}\n\t#{e.backtrace.join("\n\t")}")
					end
				else
					a.errors.add(:id, "#{a.name} - you don't have access to this Account.")
				end
                unless a.errors.empty?
					@error_message += a.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
				end
		    end
		    @message = "Account(s) deleted."
        end

        @controls_enabled = true
        respond_to do |format|
            if @error_message.blank?
                flash[:notice] = @message
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = @error_message
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @error_message, :status => :unprocessable_entity }
                format.js
            end
        end
    end

	def auto_complete_for_user_id
		super
	end
end
