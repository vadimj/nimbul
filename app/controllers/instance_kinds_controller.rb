class InstanceKindsController < ApplicationController
    before_filter :login_required
    require_role  :admin

  # GET /instance_kinds
  # GET /instance_kinds.xml
  def index
    @instance_kinds = InstanceKind.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @instance_kinds }
    end
  end

  # GET /instance_kinds/1
  # GET /instance_kinds/1.xml
  def show
    @instance_kind = InstanceKind.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @instance_kind }
    end
  end

  # GET /instance_kinds/new
  # GET /instance_kinds/new.xml
  def new
    @instance_kind = InstanceKind.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @instance_kind }
    end
  end

  # GET /instance_kinds/1/edit
  def edit
    @instance_kind = InstanceKind.find(params[:id])
  end

  # POST /instance_kinds
  # POST /instance_kinds.xml
  def create
    @instance_kind = InstanceKind.new(params[:instance_kind])

    respond_to do |format|
      if @instance_kind.save
        flash[:notice] = 'InstanceKind was successfully created.'
        format.html { redirect_to(@instance_kind) }
        format.xml  { render :xml => @instance_kind, :status => :created, :location => @instance_kind }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @instance_kind.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /instance_kinds/1
  # PUT /instance_kinds/1.xml
  def update
    @instance_kind = InstanceKind.find(params[:id])

    respond_to do |format|
      if @instance_kind.update_attributes(params[:instance_kind])
        flash[:notice] = 'InstanceKind was successfully updated.'
        format.html { redirect_to(@instance_kind) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @instance_kind.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /instance_kinds/1
  # DELETE /instance_kinds/1.xml
  def destroy
    @instance_kind = InstanceKind.find(params[:id])
    @instance_kind.destroy

    respond_to do |format|
      format.html { redirect_to(instance_kinds_url) }
      format.xml  { head :ok }
    end
  end
end
