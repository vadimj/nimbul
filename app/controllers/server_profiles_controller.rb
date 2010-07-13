class ServerProfilesController < ApplicationController
	before_filter :login_required, :except => [:index]
	require_role  :admin,
		:except => [:index],
		:unless => "params[:id].nil? or current_user.has_server_profile_access?(ServerProfile.find(params[:id])) "

    def index
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @security_groups = @provider_account.security_groups

	if @provider_account.nil?
            redirect_to new_provider_account_path and return
        end

        # refresh this provider account if a refresh was requested
        # TODO - move to a separate action
        @provider_account.refresh(params[:refresh]) if params[:refresh]

		#
		# get corresponding server_profiles
		#
		joins = nil
		server_profile_conditions = [ 'provider_account_id = ?', @provider_account.id ]
        @server_profiles = ServerProfile.search(params[:search], params[:page], joins, server_profile_conditions, params[:sort])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @server_profiles }
            format.js   { render :partial => 'server_profiles/list', :layout => false }
        end
	end
	def list
		index
	end

    # PUT /server_profiles/1
    # PUT /server_profiles/1.xml
    # PUT /server_profiles/1.js
    def update
        @server_profile = ServerProfile.find(params[:id])
        
        respond_to do |format|
            if @server_profile.update_attributes(params[:server_profile])
                flash[:notice] = 'Server Profile was successfully updated.'
                format.html { redirect_to(@server_profile) }
                format.xml  { head :ok }
                format.js   { render :partial => 'server_profiles/server_profile', :layout => false }
				format.json { render :json => @server_profile }
            else
                flash[:error] = 'There was a problem updating this Server Profile.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @server_profile.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'server_profiles/server_profile', :layout => false }
				format.json { render :json => @server_profile }
            end
        end
    end

    # PUT /server_profiles/enable
    # PUT /server_profiles/enable.xml
    def enable
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @server_profiles = ServerProfile(params[:server_profile_ids])
        @server_profiles.each do |i|
            i.update_attribute(:is_enabled, true) if current_user.has_server_profile_access?(i)
        end

        respond_to do |format|
            flash[:notice] = 'Server Profile(s) have been enabled.'
            format.html { redirect_to provider_account_server_profiles_path(@provider_account) }
            format.xml { head :ok }
        end
    end
    
end
