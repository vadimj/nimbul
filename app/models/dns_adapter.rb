require 'fileutils'
require 'pp'

class DNS_Adapter

  @@registry = {}

  DEFAULT_RENDER_TEMPLATE = '{{HOSTNAME}} {{STATE}} {{INSTANCE_ID}} {{CLUSTER_NAME}} {{SERVER_NAME}} {{ROLES}} {{PUBLIC_DNS}} {{SIMPLIFIED_HOSTNAME}}'

  def self.add_server_hostname(server, hostname)
    DnsHostnameAssignment.create(server, hostname)
  end
  
  def self.render_lease_entries(leases, include_server_info = false)
    entries = {}
    
    leases.each do |lease|
      entries[lease.hostname_base] ||= []

      hostinfo = DEFAULT_RENDER_TEMPLATE.dup

      hostinfo.gsub!('{{HOSTNAME}}', lease.fqdn)
      hostinfo.gsub!('{{STATE}}', lease.state)
      hostinfo.gsub!('{{INSTANCE_ID}}', lease.instance_id) 

      if include_server_info 
        cluster_name = lease.server.cluster.name.gsub(' ','_') rescue nil
        server_name = lease.server.name.gsub(' ','_') rescue nil
        roles = lease.server.get_server_parameter('ROLES').gsub(' ','') rescue nil
        public_dns = lease.instance.nil? ? 'Unknown_Public_Hostname' : lease.instance.public_dns 
        hostinfo.gsub!('{{CLUSTER_NAME}}', cluster_name || 'Unknown_Cluster')
        hostinfo.gsub!('{{SERVER_NAME}}', server_name || 'Unknown_Server')
        hostinfo.gsub!('{{ROLES}}', roles || 'base')
        hostinfo.gsub!('{{PUBLIC_DNS}}', public_dns)
        hostinfo.gsub!('{{SIMPLIFIED_HOSTNAME}}', lease.hostname )
      else
        hostinfo.gsub!('{{CLUSTER_NAME}}', '')
        hostinfo.gsub!('{{SERVER_NAME}}', '')
        hostinfo.gsub!('{{ROLES}}', '')
        hostinfo.gsub!('{{PUBLIC_DNS}}', '')
        hostinfo.gsub!('{{SIMPLIFIED_HOSTNAME}}', '')
      end

      entries[lease.hostname_base][lease.idx] = sprintf('%-17s %s', lease.ip, hostinfo)
    end

    return entries
  end

  def self.get_host_entries(provider, options={})
    static = []
    
    unless options[:skip_static_dns]
      static = []
      static |= provider.service_dns_records.try(:split, /\r*\n/).to_a unless options[:skip_service_dns_records]
      static |= provider.static_dns_records.try(:split, /\r*\n/).to_a
    end

    entries = {
      0 => {
        :name => 'static',
        :entries => {'static' => static }
      }
    }
  
    include_comments = options.has_key?(:include_server_info) ? (! options[:include_server_info]) : true;
  
    provider.clusters.each do |cluster|
      entries[cluster[:id]] = {
        :name    => cluster.name,
        :entries => render_lease_entries(
          DnsLease.find_all_by_cluster_id(cluster[:id]),
          options[:include_server_info]
        )
      }
    end
  
    hostfile = []
  
    # these hosts file comments are required by User Community dbslayer/memcache
    # userland apps that parse the hosts file to get information they need.
    # Removing the comments can break functionality.
  
    hostfile.push "\n#### EC2LDNS START ####\n" if include_comments
  
    entries.sort.each do |cluster_id, cluster_data|
      hostfile.push "\n# Cluster START: #{cluster_data[:name]} #" if include_comments
      cluster_data[:entries].sort.each do |host_template, hosts|
        hostfile.push "\n# Group START: #{host_template} #\n" if include_comments
        hosts.each_index { |i| hostfile.push "#{hosts[i]}\n" }
        hostfile.push "# Group END: #{host_template} #\n" if include_comments
      end
      hostfile.push "#{"\n" if cluster_data[:entries].empty?}# Cluster END: #{cluster_data[:name]} #\n" if include_comments
    end
  
    hostfile.push "\n#### EC2LDNS END ####\n" if include_comments
  
    hostfile
  end

end
