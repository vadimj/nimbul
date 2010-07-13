class Admin::UsersController < ApplicationController
	before_filter :login_required
	require_role :admin

	def index
		joins = nil
		conditions = nil
		@users = User.search(params[:search], params[:page], joins, conditions, params[:sort], params[:filter], [ :roles, :provider_accounts, :clusters ])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @users }
            format.js   { render :partial => 'shared/users_list', :layout => false }
        end
	end
	def list
		index
	end

	# Administrative activate action
	def update
		@user = User.find(params[:id], :include => [ :roles, :provider_accounts, :clusters ])
		if @user.activate!
			flash[:notice] = "User activated."
		else
			flash[:error] = "There was a problem activating this user."
		end
				
        respond_to do |format|
            format.html { redirect_to :action => 'index' }
            format.xml  { render :xml => @user }
	        format.js	{ render :partial => 'users/user.js.rjs', :object => @user, :layout => false }
        end
	end
end

