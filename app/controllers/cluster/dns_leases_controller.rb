class Cluster::DnsLeasesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id]))"

  # GET /cluster/:id/dns_leases
  def index
    @model = @cluster = Cluster.find(params[:cluster_id])
    @hostname = DnsHostname.decorate_stats(DnsHostname.find_all_by_id(params[:dns_hostname_id]), @model).first
    @leases = DnsLease.find_all_by_cluster_id_and_hostname_id(@cluster, @hostname)
    
        respond_to do |format|
            format.html { render :template => 'dns_leases/index' }
            format.xml  { render :xml => @leases }
            format.js   { render :template => 'dns_leases/index', :layout => false }
        end
  end
  
  def list
    index
  end
  
  # DELETE /clusters/:cluster_id/dns_hostnames/:dns_hostname_id/dns_leases/release
  def release
    @model = @cluster = Cluster.find(params[:cluster_id])
    @hostname = DnsHostname.decorate_stats(DnsHostname.find_all_by_id(params[:dns_hostname_id]), @model).first
    @leases = DnsLease.find_all_by_cluster_id_and_hostname_id(@cluster, @hostname)
    
    @leases.each { |l| l.release };
    
        respond_to do |format|
            format.html { head :ok }
            format.js 
        end
  end
end
