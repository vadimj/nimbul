class User::ProfilesController < ApplicationController
  before_filter :login_required, :only =>  [ :show, :edit, :update ]
  before_filter :login_prohibited, :only => [:new, :create]
   
  # This show action only allows users to view their own profile
  def show
    @user = current_user
  end  

  # render new.rhtml
  def new
    @user = SiteUser.new(:invitation_token => params[:invitation_token])
    @user_key = @user.user_keys.build({})
  end
 
  def create
    logout_keeping_session!
    
    user_params = params[:user]	
    @user = SiteUser.new(user_params)

    success = @user && @user.save
    if success && @user.errors.empty?
      # redirect_back_or_default('/')
      redirect_to new_session_path
      flash[:notice] = "Thanks for signing up! "
      flash[:notice] += ((in_beta? && @user.emails_match?) ? "You can now log into your account." : "We're sending you 														an email with your activation code.")
    else
      flash.now[:error]  = "We couldn't set up that account, sorry.  Please try again, or %s."
      flash[:error_item] = ["contact us", contact_site]
      render :action => 'new'
    end
  end

  def edit
    @user = current_user
    if !@user.identity_url.blank? && @user.crypted_password.blank?
      redirect_to edit_user_openid_account_path
    end
  end

  def update
    user_params = params[:user]
    @user = current_user
    if @user.update_attributes(user_params)
      flash[:notice] = "Profile updated."
      redirect_to :action => 'show'
    else
      flash.now[:error] = "There was a problem updating your profile."
      render :action => 'edit'
    end
  end

end
