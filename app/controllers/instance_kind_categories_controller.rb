class InstanceKindCategoriesController < ApplicationController
    before_filter :login_required
    require_role  :admin

  # GET /instance_kind_categories
  # GET /instance_kind_categories.xml
  def index
    @instance_kind_categories = InstanceKindCategory.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @instance_kind_categories }
    end
  end

  # GET /instance_kind_categories/1
  # GET /instance_kind_categories/1.xml
  def show
    @instance_kind_category = InstanceKindCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @instance_kind_category }
    end
  end

  # GET /instance_kind_categories/new
  # GET /instance_kind_categories/new.xml
  def new
    @instance_kind_category = InstanceKindCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @instance_kind_category }
    end
  end

  # GET /instance_kind_categories/1/edit
  def edit
    @instance_kind_category = InstanceKindCategory.find(params[:id])
  end

  # POST /instance_kind_categories
  # POST /instance_kind_categories.xml
  def create
    @instance_kind_category = InstanceKindCategory.new(params[:instance_kind_category])

    respond_to do |format|
      if @instance_kind_category.save
        flash[:notice] = 'InstanceKindCategory was successfully created.'
        format.html { redirect_to(@instance_kind_category) }
        format.xml  { render :xml => @instance_kind_category, :status => :created, :location => @instance_kind_category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @instance_kind_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /instance_kind_categories/1
  # PUT /instance_kind_categories/1.xml
  def update
    @instance_kind_category = InstanceKindCategory.find(params[:id])

    respond_to do |format|
      if @instance_kind_category.update_attributes(params[:instance_kind_category])
        flash[:notice] = 'InstanceKindCategory was successfully updated.'
        format.html { redirect_to(@instance_kind_category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @instance_kind_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /instance_kind_categories/1
  # DELETE /instance_kind_categories/1.xml
  def destroy
    @instance_kind_category = InstanceKindCategory.find(params[:id])
    @instance_kind_category.destroy

    respond_to do |format|
      format.html { redirect_to(instance_kind_categories_url) }
      format.xml  { head :ok }
    end
  end
end
