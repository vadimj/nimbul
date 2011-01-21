class RegionsController < ApplicationController
  parent_resources :provider
  before_filter :login_required
  require_role  :admin

  # GET /regions
  # GET /regions.xml
  def index
    @regions = parent.regions

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @regions }
      format.js	  { render :partial => 'list', :layout => false }
    end
  end

  # GET /regions/1
  # GET /regions/1.xml
  def show
    @region = Region.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @region }
    end
  end

  # GET /regions/new
  # GET /regions/new.xml
  def new
    @region = parent.regions.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @region }
    end
  end

  # GET /regions/1/edit
  def edit
    @region = parent.regions.find(params[:id])
  end

  # POST /regions
  # POST /regions.xml
  def create
    options = {}
    redirect_url = send("#{ parent_type }_regions_url", parent, options)

    if params[:cancel_button]
      redirect_to redirect_url
    else
      @region = parent.regions.build(params[:region])
      respond_to do |format|
        if @region.save
          flash[:notice] = 'Region was successfully created.'
          format.html { redirect_to redirect_url }
          format.xml  { render :xml => @region, :status => :created, :location => @region }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @region.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /regions/1
  # PUT /regions/1.xml
  def update
    options = {}
    redirect_url = send("#{ parent_type }_regions_url", parent, options)

    if params[:cancel_button]
      redirect_to redirect_url
    else
      @region = Region.find(params[:id])

      respond_to do |format|
        if @region.update_attributes(params[:region])
          flash[:notice] = 'Region was successfully updated.'
          format.html { redirect_to redirect_url }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @region.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /regions/1
  # DELETE /regions/1.xml
  def destroy
    @region = parent.regions.find(params[:id])
    @region.destroy
    
    options = {}
    redirect_url = send("#{ parent_type }_regions_url", parent, options)

    respond_to do |format|
      format.html { redirect_to redirect_url }
      format.xml  { head :ok }
    end
  end
end
