class Cluster::DnsHostnamesController < ApplicationController
  before_filter :login_required, :setup_data
  require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id])) "

  def setup_data
    hostname_id ||= params[:id] 
    (@model = Cluster.find(params[:cluster_id])).service_ancestors.each do |ancestor|
      self.instance_variable_set "@#{ancestor.class.table_name.singularize}".to_sym, ancestor
    end
    @host_servers = DnsHostname.hostname_servers(@model)
    
    @hostnames = Array(DnsHostname.paginated_model_search(@model, params, hostname_id))
    @hostname = @hostnames.first
  end
  private :setup_data

  # GET /cluster/:cluster_id/dns_hostnames
  def index
    respond_to do |format|
      format.html { render :template => 'dns_hostnames/index' }
      format.xml  { render :xml => @hostnames}
      format.js   { render :template => 'dns_hostnames/index', :layout => false }
    end
  end
  
  def list
    respond_to do |format|
      format.html { render :template => 'dns_hostnames/index' }
      format.xml  { render :xml => @hostnames}
      format.js   { render :partial => 'dns_hostnames/list', :layout => false }
    end
  end

  def show
    respond_to do |format|
      format.html {
        render :partial => 'dns_hostnames/hostname_row',
               :locals => { :hostname => @hostname, :host_servers => @host_servers }
      }
      format.xml { render :xml => @hostname }
      format.js {
        render :partial => 'dns_hostnames/hostname_row',
               :locals => { :hostname => @hostname, :host_servers => @host_servers },
               :layout => false
      }
    end
  end

  def acquire
    @error_messages = []
    
    DnsHostname.unassigned_hostname_instances(@hostname, @model).each { |i| i.acquire @hostname }

    @leases = DnsLease.find_all_by_cluster_id_and_hostname_id(@model, @hostname)
    @error_message = @error_messages.join("\n<br />")
    
    respond_to do |format|
      if @error_message.blank?
        format.xml  { head :ok }
        format.js
      else
        flash[:error] = @error_message
        format.xml  { render :xml => @error_messages, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  def destroy
    if @hostname.nil?
      @error_message = "Couldn't locate Hostname [#{params[:dns_hostname][:id]}]"
    elsif @hostname.leases[:active] > 0
      @error_message = "Can not remove hostname '#{@hostname.name}' while it is in use (active leases: #{@hostname.leases[:active]})"
    else
      begin
        @hostname.destroy
        @message = "Deleted '#{@hostname.name}'"
      rescue
        @error_message = "Failed to delete '#{@hostname.name}': #{$!}"
        @hostname.status_message = "Failed to remove: #{$!}"
      end
    end
        
    respond_to do |format|
      if @error_message.blank?
        flash[:notice] = @message
        format.html { redirect_to @model, :anchor => 'dns'  }
        format.xml  { head :ok }
        format.js
      else
        flash[:error] = @error_message
        format.html { redirect_to @model, :anchor => 'dns' }
        format.xml  { render :xml => @hostname.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end
end
