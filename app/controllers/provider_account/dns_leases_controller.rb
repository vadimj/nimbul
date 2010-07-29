class ProviderAccount::DnsLeasesController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id]))"

  # GET /provider_account/:id/dns_leases
  def index
    @model = @provider_account = ProviderAccount.find(params[:provider_account_id])
    @hostname = DnsHostname.decorate(DnsHostname.find_all_by_id(params[:dns_hostname_id]), @model).first
    @leases = DnsLease.find_all_by_provider_account_id_and_hostname_id(@provider_account, @hostname)
    
        respond_to do |format|
            format.html { render :template => 'dns_leases/index' }
            format.xml  { render :xml => @leases }
            format.js   { render :template => 'dns_leases/index', :layout => false }
        end
  end
  
  def list
    index
  end
  
  # DELETE /provider_accounts/:provider_account_id/dns_hostnames/:dns_hostname_id/dns_leases/release
  def release
    @model = @provider_account = ProviderAccount.find(params[:provider_account_id])
    @hostname = DnsHostname.decorate(DnsHostname.find_all_by_id(params[:dns_hostname_id]), @model).first
    @leases = DnsLease.find_all_by_provider_account_id_and_hostname_id(@provider_account, @hostname)
    
    @leases.each { |l| l.release };
    
        respond_to do |format|
            format.html { head :ok }
            format.js 
        end
  end
end
