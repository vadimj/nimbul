class Service::TypesController < ApplicationController
  before_filter :login_required
  require_role :admin

  def index
    @service_types = ServiceType.all
  end
  
  def show
    @service_type = ServiceType.find(params[:id])
  end
  
  def new
    @service_type = ServiceType.new
  end
  
  def create
    if params[:cancel_button]
      redirect_to service_types_url
    else
      @service_type = ServiceType.new(params[:service_type])
      if @service_type.save
        flash[:notice] = "Successfully created service type."
        redirect_to service_types_url
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    @service_type = ServiceType.find(params[:id])
  end
  
  def update
    if params[:cancel_button]
      redirect_to service_types_url
    else
      @service_type = ServiceType.find(params[:id])
      if @service_type.update_attributes(params[:service_type])
        flash[:notice] = "Successfully updated service type."
        redirect_to service_types_url
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    @service_type = ServiceType.find(params[:id])
    @service_type.destroy
    flash[:notice] = "Successfully destroyed service type."
    redirect_to service_types_url
  end
end
