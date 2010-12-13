class InstanceTypeCategoriesController < ApplicationController
    before_filter :login_required
    require_role  :admin

  # GET /instance_type_categories
  # GET /instance_type_categories.xml
  def index
    @instance_type_categories = InstanceTypeCategory.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @instance_type_categories }
    end
  end

  # GET /instance_type_categories/1
  # GET /instance_type_categories/1.xml
  def show
    @instance_type_category = InstanceTypeCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @instance_type_category }
    end
  end

  # GET /instance_type_categories/new
  # GET /instance_type_categories/new.xml
  def new
    @instance_type_category = InstanceTypeCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @instance_type_category }
    end
  end

  # GET /instance_type_categories/1/edit
  def edit
    @instance_type_category = InstanceTypeCategory.find(params[:id])
  end

  # POST /instance_type_categories
  # POST /instance_type_categories.xml
  def create
    @instance_type_category = InstanceTypeCategory.new(params[:instance_type_category])

    respond_to do |format|
      if @instance_type_category.save
        flash[:notice] = 'InstanceTypeCategory was successfully created.'
        format.html { redirect_to(@instance_type_category) }
        format.xml  { render :xml => @instance_type_category, :status => :created, :location => @instance_type_category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @instance_type_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /instance_type_categories/1
  # PUT /instance_type_categories/1.xml
  def update
    @instance_type_category = InstanceTypeCategory.find(params[:id])

    respond_to do |format|
      if @instance_type_category.update_attributes(params[:instance_type_category])
        flash[:notice] = 'InstanceTypeCategory was successfully updated.'
        format.html { redirect_to(@instance_type_category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @instance_type_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /instance_type_categories/1
  # DELETE /instance_type_categories/1.xml
  def destroy
    @instance_type_category = InstanceTypeCategory.find(params[:id])
    @instance_type_category.destroy

    respond_to do |format|
      format.html { redirect_to(instance_type_categories_url) }
      format.xml  { head :ok }
    end
  end
end
