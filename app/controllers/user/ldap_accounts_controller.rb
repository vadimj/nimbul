require 'ldap_connect'

class User::LdapAccountsController < ApplicationController
	before_filter :login_prohibited, :only => [ :new, :create ]
	before_filter :login_required, :only => [ :edit, :update ]

	def new
	end

	def create
		logout_keeping_session!
		LDAP.authenticate(params[:user][:login], params[:user][:password]) && @user = LdapUser.new(
			:login => params[:user][:login],
			:email => LDAP.get_email(params[:user][:login]),
			:name => LDAP.get_name(params[:user][:login]),
			:invitation_token => params[:user][:invitation_token])
		success = @user && @user.save
		if success && @user.errors.empty?
			flash[:notice] = "Thanks for signing up! "
			flash[:notice] += ((in_beta? && @user.emails_match?) ? "You can now log into your account." : "We're sending you 														an email with your activation code.")
			redirect_back_or_default('/')
		else
			flash.now[:error]  = "Sorry, we couldn't set up that account.  Please correct the errors and try again, or %s."
			flash[:error_item] = ["sign up for a regular account", new_user_profile_path]
			render :action => 'new'
		end
	end

	def edit
		@user = LdapUser.find(current_user.login)
	end

	def update
		@user = LdapUser.find(current_user.login)
		if @user.update_attributes(
			:name  => params[:user][:name],
			:email => params[:user][:email]
		)
			flash[:notice] = "Profile updated."
			redirect_to user_profile_path
		else
			flash.now[:error] = "There was a problem updating your profile."
			render :action => 'edit'
		end
	end
end

