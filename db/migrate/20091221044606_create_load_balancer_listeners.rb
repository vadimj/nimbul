class CreateLoadBalancerListeners < ActiveRecord::Migration
  def self.up
    create_table :load_balancer_listeners do |t|
      t.integer :load_balancer_id
      t.integer :load_balancer_port
      t.integer :instance_port
      t.string :protocol

      t.timestamps
    end
    add_index :load_balancer_listeners, [ :load_balancer_id, :load_balancer_port, :instance_port, :protocol ], :unique => true, :name => :index_ports_on_listener
  end

  def self.down
    drop_table :load_balancer_listeners
  end
end
