class FixLoadBalancersTable < ActiveRecord::Migration
  def self.up
    drop_table :load_balancers
	create_table :load_balancers do |t|
	  t.integer :provider_account_id
	  t.string :load_balancer_name
      t.datetime :created_time
	  t.string :d_n_s_name

	  t.timestamps
	end
	add_index :load_balancers, [:provider_account_id, :load_balancer_name], :name => 'index_on_load_balancers_pa_id_and_lb_name'
  end

  def self.down
    drop_table :load_balancers
	create_table :load_balancers do |t|
	  t.integer :launch_configuration_id
	  t.string :name
	  
	  t.timestamps
	end
	add_index :load_balancers, :launch_configuration_id
  end
end
