class CreateDnsHostnameAssignments < ActiveRecord::Migration
  def self.up
    create_table :dns_hostname_assignments do |t|
      t.primary_key :id
      t.integer :dns_hostname_id, :null => false, :sign => :unsigned
      t.integer :server_id, :null => false, :sign => :unsigned
      t.timestamps
    end
    
    add_index(
	  :dns_hostname_assignments,
	  [ :server_id, :dns_hostname_id ],
	  :unique => true,
	  :name => 'unique_server_hostname_idx'
	)
    
  end

  def self.down
    drop_table :dns_hostname_assignments
  end
end
