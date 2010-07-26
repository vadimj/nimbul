class ProviderAccount::DnsHostnamesController < ApplicationController
  before_filter :login_required
  require_role  :admin, :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id])) "
  after_filter :setup_data
  
  def setup_data 
    hostname_id ||= params[:id] 
    (@model = ProviderAccount.find(params[:provider_account_id])).service_ancestors.each do |ancestor|
      puts %Q|self.instance_variable_set "@#{ancestor.class.table_name.singularize}".to_sym, ancestor|
      self.instance_variable_set "@#{ancestor.class.table_name.singularize}".to_sym, ancestor
    end
    
    @host_servers = DnsHostname.hostname_servers(@model)

    if not hostname_id.nil?
      @hostname = DnsHostname.paginated_model_search(@model, params, hostname_id)
    else
      @hostnames = DnsHostname.paginated_model_search(@model, params)
    end      
  end
  private :setup_data
  
  # GET /provider_accounts/:id/dns_hostnames
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
      format.html { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname } }
      format.xml { render :xml => @hostname }
      format.js { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname }, :layout => false }
    end
  end
  
  # auto_complete_for :dns_hostname, :login
  def auto_complete_for_dns_hostname_id(options = {})
    @provider_account = ProviderAccount.find(params[:provider_account_id])
    @search = params[:dns_hostname_search]
    conditions = [ "provider_account_id=? and (LOWER(name) LIKE ?)" ]
    conditions << @provider_account.id
    conditions << ('%' + @search + '%')
    order = 'name ASC'
    find_options = {
      :conditions => conditions,
      :order => order,
      :limit => 10 }.merge!(options)

    @hostnames = DnsHostname.find(:all, find_options)

    tags = "<%= content_tag(:ul, @hostnames.map{ |hostname| content_tag(:li, dns_hostname_description(hostname, @search)) }) %>"
    render :inline => tags
  end

  def create
    @model = @provider_account = ProviderAccount.find(params[:provider_account_id])

    if params[:dns_hostname][:id] == 'Add Hostname'
      return respond_to do |format|
        format.html  { redirect_to @provider_account, :anchor => :dns }
        format.js    { head :ok }
        format.xml   { head :ok }
      end
    end
    
    create_attempted  = false
    invalid_hostname = false
    
    @hostname = case params[:dns_hostname][:id]
      when /^\d+$/:
        DnsHostname.find_by_id_and_provider_account_id(params[:dns_hostname][:id], @provider_account.id)
      when DnsHostname::VALID_HOSTNAME_REGEX:
        hostname = DnsHostname.find_by_name_and_provider_account_id(params[:dns_hostname][:id], @provider_account)
        if hostname.nil?
          create_attempted = true
          hostname = @provider_account.dns_hostnames.create :name => params[:dns_hostname][:id]
        end
        hostname
      else
        invalid_hostname = true
        nil
    end
    
    if @hostname.nil?
      if create_attempted
        @error_message = "Unable to find or create hostname identified by '#{params[:dns_hostname][:id]}'"
      elsif invalid_hostname
        @error_message = "Invalid hostname '#{params[:dns_hostname][:id]}'!! Hostname must begin with a letter and contain only alpha-numeric, underscore and dash characters."
      else
        @error_message = "Unable to find hostname identified by '#{params[:dns_hostname][:id]}'"
      end
    else
      if not create_attempted
        @error_message = "Hostname '#{@hostname.name}' already exists for provider account '#{@provider_account.name}' !" 
      end
    end

    respond_to do |format|
      if @error_message.blank?
        flash[:notice] = @message
        format.html { redirect_to @provider_account }
        format.xml  { head :ok }
        format.js
      else
        flash[:error] = @error_message
        format.html { redirect_to @provider_account }
        format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end
    
  def acquire
    @error_messages = []
    
    assignments = if @hostname.nil?
      @model.clusters.inject([]) { |a,cluster| a = a | cluster.servers.inject([]) { |a,s| a = a | DnsHostnameAssignment.find_all_by_server_id(s); a }; a }
    else
      @model.clusters.inject([]) { |a,cluster| a = a | cluster.servers.inject([]) { |a,s| a = a | DnsHostnameAssignment.find_all_by_server_id_and_dns_hostname_id(s, @hostname); a }; a }
    end
    
    instances = assignments.inject([]) do |array,assignment|
      array = array | assignment.server.instances.select { |i| not i.has_dns_lease? assignment }; array
    end
    
    instances.each { |i| i.acquire @hostname }

    @leases = DnsLease.find_all_by_provider_account_id_and_hostname_id(@model, @hostname)
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
    @model = @provider_account = ProviderAccount.find(params[:provider_account_id])
    @hostname = DnsHostname.find(params[:id])        

    if @hostname.nil?
      @error_message = "Couldn't locate Hostname [#{params[:dns_hostname][:id]}]"
    elsif @hostname.has_active_leases? 
      @error_message = "Can not remove hostname '#{@hostname.name}' while it is in use (active leases: #{@hostname.active_leases.size})"
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