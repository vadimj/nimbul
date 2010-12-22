class ProvidersController < ApplicationController
  before_filter :login_required
  require_role  :admin

  # GET /providers
  # GET /providers.xml
  def index
    @providers = Provider.find(:all, :order => 'name')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @providers }
    end
  end

  # GET /providers/1
  # GET /providers/1.xml
  def show
    @provider = Provider.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @provider }
    end
  end

  # GET /providers/new
  # GET /providers/new.xml
  def new
    @provider = Provider.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @provider }
    end
  end

  # GET /providers/1/edit
  def edit
    @provider = Provider.find(params[:id])
  end

  # POST /providers
  # POST /providers.xml
  def create
    options = {}
    redirect_url = providers_url

    if params[:cancel_button]
      redirect_to redirect_url
    else
      @provider = Provider.new(params[:provider])

      respond_to do |format|
        if @provider.save
          flash[:notice] = 'Provider was successfully created.'
          format.html { redirect_to redirect_url }
          format.xml  { render :xml => @provider, :status => :created, :location => @provider }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @provider.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /providers/1
  # PUT /providers/1.xml
  def update
    options = {}
    redirect_url = providers_url

    if params[:cancel_button]
      redirect_to redirect_url
    else
      @provider = Provider.find(params[:id])

      respond_to do |format|
        if @provider.update_attributes(params[:provider])
          flash[:notice] = 'Provider was successfully updated.'
          format.html { redirect_to redirect_url }
          format.xml  { head :ok }
          format.json { render :json => @provider }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @provider.errors, :status => :unprocessable_entity }
          format.json { render :json => @provider }
        end
      end
    end
  end

  # DELETE /providers/1
  # DELETE /providers/1.xml
  def destroy
    @provider = Provider.find(params[:id])
    @provider.destroy

    respond_to do |format|
      format.html { redirect_to(providers_url) }
      format.xml  { head :ok }
    end
  end
end
