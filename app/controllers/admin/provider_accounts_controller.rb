class Admin::ProviderAccountsController < ApplicationController
	before_filter :login_required
	require_role :admin

	def index
		@user = User.find(params[:user_id], :include => [ :provider_accounts, :clusters ])
		@provider_accounts = ProviderAccount.find(:all, :order => :name, :include => :clusters)
	end

	def update
		@user = User.find(params[:user_id])
		@provider_accounts = (ProviderAccount.find(params[:user][:provider_account_ids])) if params[:user][:provider_account_ids]
        @user.provider_accounts = (@provider_accounts || [])
		@clusters = (Cluster.find(params[:user][:cluster_ids])) if params[:user][:cluster_ids]
		@user.clusters = (@clusters || [])
		if @user.save
			flash[:notice] = 'Access rules were successfully updated.'
			redirect_to admin_user_provider_accounts_path(@user)
		else
			flash[:error] = 'There was a problem updating access rules.'
			redirect_to admin_user_provider_accounts_path(@user)
		end
	end

end

