class Cluster::AddressesController < ApplicationController
  before_filter :login_required
  require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

  def index
    @cluster = Cluster.find(params[:cluster_id])
    
    joins = nil
    conditions = nil
	@addresses  = CloudAddress.find_all_by_cluster(@cluster, params[:search], params[:page], joins, conditions, params[:sort])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @addresses }
      format.js
    end
  end
  def list
  	index
  end
end
