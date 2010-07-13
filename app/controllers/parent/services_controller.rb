class Parent::ServicesController < ApplicationController
  parent_resources :provider, :provider_account, :cluster, :server
  before_filter :login_required
  require_role  :admin, :unless => "current_user.has_access?(parent)"

  def index
    @services = parent_object.services
    @parent_type = parent_type
    @parent = parent

    respond_to do |format|
      format.html
      format.xml  { render :xml => @instances }
      format.js
    end
  end

  def list
    index
  end

  def new
    @address = CloudAddress.new

    @controls_enabled = true
    respond_to do |format|
      format.html
      format.xml  { render :xml => @address }
      format.js
    end
  end

  def create
    @address = parent.addresses.build(params[:address])

    @controls_enabled = true
    respond_to do |format|
      if @address.save and @address.allocate!
        flash[:notice] = 'Address was successfully allocated.'
        format.html { redirect_to parent, :anchor => 'addresses' }
        format.xml  { render :xml => @address, :status => :created, :location => @address }
        format.js
      else
        @error_message ||= @address.errors.collect{ |e| e[0].humanize+' - '+e[1] }.join('<br />')
        flash[:error] = @error_message
        format.html { render :action => "new" }
        format.xml  { render :xml => @address.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end
end