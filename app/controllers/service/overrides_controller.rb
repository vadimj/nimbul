class Service::OverridesController < ApplicationController
  before_filter :login_required
  require_role :admin

  def index
    @service_overrides = ServiceOverride.all
  end
  
  def show
    @service_override = ServiceOverride.find(params[:id])
  end
  
  def new
    @service_override = ServiceOverride.new
  end
  
  def create
    if params[:cancel_button]
      redirect_to service_overrides_url
    else
      override_params = params[:service_override]
      override_params['target_type'] = override_params['target_id'].to_s[/^([^:]+)/,1]
      override_params['target_id']   = override_params['target_id'].to_s[/^[^:]+:(\d+)/,1]
      
      @service_override = ServiceOverride.new(override_params)
      if @service_override.save
        flash[:notice] = "Successfully created service override."
        redirect_to service_overrides_url
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    @service_override = ServiceOverride.find(params[:id])
  end
  
  def update
    if params[:cancel_button]
      redirect_to service_overrides_url
    else
      @service_override = ServiceOverride.find(params[:id])
  
      override_params = params[:service_override]
      override_params['target_type'] = override_params['target_id'].to_s[/^([^:]+)/,1]
      override_params['target_id']   = override_params['target_id'].to_s[/^[^:]+:(\d+)/,1]
  
      if @service_override.update_attributes(override_params)
        flash[:notice] = "Successfully updated service override."
        redirect_to service_overrides_url
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    @service_override = ServiceOverride.find(params[:id])
    @service_override.destroy
    flash[:notice] = "Successfully destroyed service override."
    redirect_to service_overrides_url
  end
end
