class CreateDnsRequests < ActiveRecord::Migration
  def self.up
    create_table :dns_requests do |t|
      t.primary_key :id
      t.column  :request_type, :enum, :limit => [:release, :acquire], :default => :acquire, :null => false
      t.integer :dns_hostname_assignment_id, :null => false, :sign => :unsigned
      t.integer :instance_id, :null => false, :sign => :unsigned

      t.timestamps
    end
    
    add_index(
	  :dns_requests,
	  [ :dns_hostname_assignment_id, :request_type, :instance_id ],
	  
	  # there could be multiple requests for release/acquire for a given instance depending on processing speed
	  :unique => false, 
	  
	  :name => 'hostname_assignment_request_instance_idx'
	)
  end

  def self.down
    drop_table :dns_requests
  end
end
