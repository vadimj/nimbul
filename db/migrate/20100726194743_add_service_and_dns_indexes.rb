class AddServiceAndDnsIndexes < ActiveRecord::Migration
  def self.up
    # DNS Related
    add_index :dns_leases, [ :dns_hostname_assignment_id, :idx ]
    add_index :dns_hostname_assignments, :server_id
    add_index :dns_hostnames, :name, :length => 16
    add_index :dns_requests, :request_type
    add_index :dns_requests, :instance_id
    
    # Service Related
    add_index :service_overrides, [ :target_id, :target_type ], :length => { :target_type => 16 } 
    add_index :service_providers, :server_id
    
    # server profile revision related
    add_index :server_profile_revision_parameters, :server_profile_revision_id, :name => 'index_sprp_spr_id'
  end

  def self.down
    # DNS Related
    remove_index :dns_leases, [ :dns_hostname_assignment_id, :idx ]
    remove_index :dns_hostname_assignments, :server_id
    remove_index :dns_hostnames, :name
    remove_index :dns_requests, :request_type
    remove_index :dns_requests, :instance_id
    
    # Service Related
    remove_index :service_overrides, [ :target_id, :target_type ]
    remove_index :service_providers, :server_id

    # server profile revision related
    remove_index :server_profile_revision_parameters, :server_profile_revision_id
  end
end
