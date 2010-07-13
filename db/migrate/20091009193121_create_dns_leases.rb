class CreateDnsLeases < ActiveRecord::Migration
  def self.up
    create_table :dns_leases do |t|
      t.primary_key :id
      t.integer :dns_hostname_assignment_id, :null => false, :sign => :unsigned
      t.integer :instance_id, :null => true, :sign => :unsigned
      t.integer :idx, :default => 0, :sign => :unsigned, :null => false
      t.timestamps
    end

	add_index(
	  :dns_leases,
	  [ :instance_id, :dns_hostname_assignment_id ],
	  :unique => true,
	  :name => 'unique_instance_hostname_assignment_idx'
	)
  end

  def self.down
    drop_table :dns_leases
  end
end
