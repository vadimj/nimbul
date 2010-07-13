class DropExtraConstraints < ActiveRecord::Migration
  def self.up
    remove_index :firewall_rules, [ :provider_account_id, :name ]
    remove_index :server_images, [ :provider_account_id, :name ]
    remove_index :volumes, [ :provider_account_id, :name ]
    remove_index :addresses, [ :provider_account_id, :name ]
    remove_index :cluster_parameters, [ :cluster_id, :name ]
    remove_index :server_parameters, [ :server_id, :name ]
    remove_index :servers, [ :provider_account_id, :name ]
  end

  def self.down
    add_index :firewall_rules, [ :provider_account_id, :name ], :unique => true
    add_index :server_images, [ :provider_account_id, :name ], :unique => true
    add_index :volumes, [ :provider_account_id, :name ], :unique => true
    add_index :addresses, [ :provider_account_id, :name ], :unique => true
    add_index :cluster_parameters, [ :cluster_id, :name ], :unique => true
    add_index :server_parameters, [ :server_id, :name ], :unique => true
    add_index :servers, [ :provider_account_id, :name ], :unique => true
  end
end
