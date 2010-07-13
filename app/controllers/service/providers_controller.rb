class Service::ProvidersController < ApplicationController
  before_filter :login_required
  require_role :admin

  def prepare_resources
    @provider_accounts = ProviderAccount.find(:all, :order => 'name')
    @clusters = Cluster.find(:all, :order => 'name')
    @servers = Server.find(:all, :order => 'name')
  end

  def index
    @service_providers = ServiceProvider.all
  end
  
  def show
    @service_provider = ServiceProvider.find(params[:id])
  end
  
  def new
    prepare_resources
    @service_provider = ServiceProvider.new
  end
  
  def create
    if params[:cancel_button]
      redirect_to service_providers_url
    else
      prepare_resources
      @service_provider = ServiceProvider.new(params[:service_provider])
      if @service_provider.save
        flash[:notice] = "Successfully created service provider."
        redirect_to service_providers_url
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    prepare_resources
    @service_provider = ServiceProvider.find(params[:id])
  end
  
  def update
    if params[:cancel_button]
      redirect_to service_providers_url
    else
      prepare_resources
      @service_provider = ServiceProvider.find(params[:id])
      if @service_provider.update_attributes(params[:service_provider])
        flash[:notice] = "Successfully updated service provider."
        redirect_to service_providers_url
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    @service_provider = ServiceProvider.find(params[:id])
    @service_provider.destroy
    flash[:notice] = "Successfully destroyed service provider."
    redirect_to service_providers_url
  end

    def auto_complete_for_service_provider_server_name(options = {})
        @search = params[:server_search]
        @servers = Server.find(:all,
          :conditions => [ 'LOWER(name) LIKE ?',
          '%' + params[:service_provider][:server_name].downcase + '%' ],
          :order => 'name ASC',
          :limit => 10,
          :include => :cluster)

        tags = "<%= content_tag(:ul, @servers.map{ |server| content_tag(:li, server_description(server, @search), :id => server.id) }) %>"
        render :inline => tags
    end
end
