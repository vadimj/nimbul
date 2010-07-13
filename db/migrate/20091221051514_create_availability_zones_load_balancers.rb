class CreateAvailabilityZonesLoadBalancers < ActiveRecord::Migration
  def self.up
    create_table :availability_zones_load_balancers, :id => false do |t|
      t.integer :availability_zone_id, :load_balancer_id
    end
    add_index :availability_zones_load_balancers, :availability_zone_id, :name => 'index_az_id_on_azslbs'
    add_index :availability_zones_load_balancers, :load_balancer_id, :name => 'index_lb_id_on_azslbs'
  end

  def self.down
    drop_table :availability_zones_load_balancers
  end
end
