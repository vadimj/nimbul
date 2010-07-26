class Server::DnsHostnamesController < ApplicationController
  before_filter :login_required
  require_role  :admin, :unless => "current_user.has_server_access?(Server.find(params[:server_id])) "

  def setup_data hostname_id = nil
    (@model = Server.find(params[:server_id])).service_ancestors.each do |ancestor|
      self.instance_variable_set "@#{ancestor.class.table_name.singularize}".to_sym, ancestor
    end
    
    @host_servers = DnsHostname.hostname_servers(@model)
    @hostnames = DnsHostname.paginated_model_search(@model, params, hostname_id)  
  end
  private :setup_data
  
  # GET /servers/:id/dns_hostnames
  def index
    setup_data()
    
    respond_to do |format|
      format.html { render :template => 'dns_hostnames/index' }
      format.xml  { render :xml => @hostnames}
      format.js   { render :template => 'dns_hostnames/index', :layout => false }
    end
  end
  
  def list
    setup_data()
    
    respond_to do |format|
      format.html { render :template => 'dns_hostnames/index' }
      format.xml  { render :xml => @hostnames}
      format.js   { render :partial => 'dns_hostnames/list', :layout => false }
    end
  end

  def show
    setup_data params[:id]
    @hostname = @hostnames.first
    
    respond_to do |format|
      format.html { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname } }
      format.xml { render :xml => @hostname }
      format.js { render :partial => 'dns_hostnames/hostname_row', :locals => { :hostname => @hostname }, :layout => false }
    end
  end
  
  # auto_complete_for :dns_hostname, :login
  def auto_complete_for_dns_hostname_id(options = {})
    @server = Server.find(params[:server_id])
    @provider_account = @server.cluster.provider_account
    @search = params[:dns_hostname_search]

    find_options = {
      :conditions => [ "provider_account_id=? and (LOWER(name) LIKE ?)", @provider_account.id, "%#{@search}%" ],
      :order =>'name ASC',
      :limit => 10
    }.merge!(options)

    @hostnames = DnsHostname.find(:all, find_options).select do |hostname|
      not @server.dns_hostnames.include? hostname
    end

    tags = "<%= content_tag(:ul, @hostnames.map{ |hostname| content_tag(:li, dns_hostname_description(hostname, @search)) }) %>"
    render :inline => tags
  end

  def create
    @model = @server = Server.find(params[:server_id])
    @cluster = @server.cluster
    @provider_account = @cluster.provider_account
    
    if params[:dns_hostname][:id] == 'Add Hostname'
      return respond_to do |format|
        format.html  { redirect_to @server, :anchor => :dns }
        format.js    { head :ok }
        format.xml   { head :ok }
      end
    end

    @invalid_hostname = false
    @create_attempted = false

    @error_message = ''
    
    # search for existing dns name or create a new one
    @hostname = case params[:dns_hostname][:id]
      when /^\d+$/:
        DnsHostname.find_by_id_and_provider_account_id(params[:dns_hostname][:id], @provider_account.id)
      when DnsHostname::VALID_HOSTNAME_REGEX:
        hostname = DnsHostname.find_by_name_and_provider_account_id(params[:dns_hostname][:id], @provider_account)
        if hostname.nil?
          hostname = @provider_account.dns_hostnames.create(:name => params[:dns_hostname][:id])
        end
        if hostname.errors.empty?
          hostname
        else
          @error_message += '<br/>' +hostname.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
          nil
        end
      else
        @error_message = "Invalid hostname '#{params[:dns_hostname][:id]}'!! Hostname must begin with a letter and contain only alpha-numeric, underscore and dash characters."
        nil
    end

    # create a new dns assignment
    if @error_message.blank?
      @assignment = DnsHostnameAssignment.find_by_server_id_and_dns_hostname_id(@server, @hostname)
      if @assignment.nil?
        @assignment = @server.dns_hostname_assignments.create(:dns_hostname_id => @hostname.id)
      else
        @error_message = "Hostname '#{@hostname.name}' already assigned to server '#{@server.name}'"
      end
        unless @assignment.errors.empty?
        @error_message += '<br/>' + @assignment.errors.collect{ |attr,msg| attr.humanize+' - '+msg }.join('<br />')
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

  def destroy
    @model = @server = Server.find(params[:server_id])
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

  def acquire
    @model = @server = Server.find(params[:server_id])
    @hostname = DnsHostname.find(params[:id])
    
    @error_messages = []
    
    assignments = if @hostname.nil?
      DnsHostnameAssignment.find_all_by_server_id(@server)
    else
      DnsHostnameAssignment.find_all_by_server_id_and_dns_hostname_id(@server, @hostname)
    end
    
    assignments.each do |assignment|
      begin
        @server.instances.select{ |i| not i.has_dns_lease? assignment }.each{ |i| assignment.acquire i }
      rescue Exception => e
        @error_messages << "Error acquire hostname: #{e.message}"
        next
      end
    end

    @leases = DnsLease.find_all_by_server_id_and_hostname_id(@server, @hostname)
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
    
  def unassign
    @model = server = Server.find(params[:server_id]) 
    hostname = DnsHostname.find(params[:id])
    
    begin
      assignment = DnsHostnameAssignment.find_by_server_id_and_dns_hostname_id(server, hostname)
      unless assignment.nil?
        if assignment.has_active_leases?
          @error_message = "Unable to unassign hostname #{hostname.name} from server '#{server.name}' when it has active leases."
        else
          unless assignment.destroy
            @error_message = "Unable to remove hostname assignment for '#{hostname.name}' from server '#{server.name}' - reason: #{assignment.errors.join("\n")}"
          end
        end
      end
    rescue Exception => e
      @error_message = "Error during deletion of hostname assignment: " << $!
    end

    hostname.reload
    
    respond_to do |format|
      if @error_message.blank?
        format.xml  { head :ok }
        format.js
      else
        flash[:error] = @error_message
        format.xml  { render :xml => assignment.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end
end
