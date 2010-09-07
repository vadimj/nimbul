class Admin::StatesController < ApplicationController
	before_filter :login_required
	require_role :admin

  def update
    @user = User.find(params[:id])
    if @user.enable!
      flash[:notice] = "User enabled."
    else
      flash[:error] = "There was a problem enabling this user."
    end
    
    respond_to do |format|
        format.html { redirect_to admin_users_path }
        format.xml  { render :xml => @user }
        format.js	{ render :partial => 'users/user.js.rjs', :object => @user, :layout => false }
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.disable!
      flash[:notice] = "User disabled."
    else
      flash[:error] = "There was a problem disabling this user."
    end
    
    respond_to do |format|
        format.html { redirect_to admin_users_path }
        format.xml  { render :xml => @user }
        format.js	{ render :partial => 'users/user.js.rjs', :object => @user, :layout => false }
    end
  end

end
