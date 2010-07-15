class PublishersController < ApplicationController
	before_filter :login_required
	require_role  :admin,
		:unless => "params[:id].nil? or current_user.has_publisher_access?(Publisher.find(params[:id])) "

	# GET /publishers
	# GET /publishers.xml
	# GET /publishers.js
	def index
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @publishers = @provider_account.publishers

        respond_to do |format|
            format.html
            format.xml  { render :xml => @publishers }
            format.js   { render :partial => 'list', :layout => false }
        end
	end
	def list
		index
	end

	# GET /publishers/1
	# GET /publishers/1.xml
	def show
		@publisher = Publisher.find(params[:id])
		@users = User.find(:all, :order => :login)
        joins = nil
        conditions = [ 'publisher_id = ?', @publisher.id ]
        @servers = Server.search(params[:search], params[:page], joins, conditions, params[:sort])

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @publisher }
		end
	end

    # GET /publishers/new
    # GET /publishers/new.xml
    def new
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @class_type = 'Publishers::'+params[:class_type] unless params[:class_type].blank?
        @publisher = Publisher.factory(@class_type)

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @publisher }
            format.js
        end
    end

	# GET /publishers/1/edit
	# GET /publishers/1/edit.json
	def edit
		@provider_accounts = provider_accounts_for_user
		@publisher = Publisher.find(params[:id])
		@users = User.find(:all, :order => :login)
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @publisher }
		end
	end

    # POST /publishers
    # POST /publishers.xml
    def create
	@provider_account = ProviderAccount.find(params[:provider_account_id])
        redirect_url = provider_account_path(@provider_account, :anchor => :communication)
	    if params[:cancel_button]
                redirect_back_or_default(redirect_url)
            else
		@publisher = @provider_account.publishers.build(params[:publisher])

        redirect_url = provider_account_path(@provider_account, :anchor => :communication)
        
        respond_to do |format|
	if @provider_account && !current_user.has_provider_account_access?(@provider_account)
                flash[:error] = "You don't have permisson to add Publishers to #{@provider_account.name}"
                format.html { render :action => "new" }
                format.xml  { render :xml => @publisher.errors, :status => :unprocessable_entity }
            elsif @publisher.save
                flash[:notice] = 'Publisher was successfully created.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @publisher, :status => :created, :location => @publisher }
			else				
                format.html { render :action => "new" }
                format.xml  { render :xml => @publisher.errors, :status => :unprocessable_entity }
            end
          end
        end
    end

    # PUT /publishers/1
    # PUT /publishers/1.xml
    # PUT /publishers/1.js
    def update
        @publisher = Publisher.find(params[:id])
        @provider_account = @publisher.provider_account
        redirect_url = provider_account_path(@provider_account, :anchor => :communication)

	    if params[:cancel_button]
            redirect_back_or_default(redirect_url)
        else
	        respond_to do |format|
	            if @publisher.update_attributes(params[:publisher])
	                flash[:notice] = 'Publisher was successfully updated.'
	                format.html { redirect_to redirect_url }
	                format.xml  { head :ok }
	                format.js   { render :partial => 'publisher', :layout => false }
					format.json { render :json => @publisher }
	            else
	                flash[:error] = 'There was a problem updating this Publisher.'
	                format.html { render :action => "edit" }
	                format.xml  { render :xml => @publisher.errors, :status => :unprocessable_entity }
	                format.js   { render :partial => 'publisher', :layout => false }
					format.json { render :json => @publisher }
	            end
	        end
        end
    end
    
    def run
		@publisher = Publisher.find(params[:id])
		@provider_account = @publisher.provider_account
    
		redirect_url = provider_account_path(@provider_account, :anchor => :communication)
		
        respond_to do |format|
            if @publisher.publish!
                flash[:notice] = 'Publisher ran successfully.'
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = 'There was a problem running this Publisher: '+@publisher.state_text
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @publisher.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
    
    def verify
		@publisher = Publisher.find(params[:id])
		@provider_account = @publisher.provider_account
    
		redirect_url = provider_account_path(@provider_account, :anchor => :communication)
		
        respond_to do |format|
            if @publisher.is_configuration_good?
                flash[:notice] = 'Publisher verified successfully.'
                format.html { redirect_to redirect_url }
                format.xml  { head :ok }
                format.js
            else
                flash[:error] = 'There was a problem verifying this Publisher: '+@publisher.state_text
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @publisher.errors, :status => :unprocessable_entity }
                format.js
            end
        end
    end
    
	def destroy
		@publisher = Publisher.find(params[:id])
		@provider_account = @publisher.provider_account
		@publisher.destroy
		
		redirect_url = provider_account_path(@provider_account, :anchor => :communication)

		respond_to do |format|
			format.html { redirect_to @cluster }
			format.xml  { head :ok }
			format.js
		end
	end
    
  	def auto_complete_for_user_id
	  super
  	end
end
