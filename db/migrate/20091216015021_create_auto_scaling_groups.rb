class CreateAutoScalingGroups < ActiveRecord::Migration
  def self.up
    create_table :auto_scaling_groups do |t|
      t.primary_key :id
      t.integer :launch_configuration_id
      t.integer :provider_account_id

      t.string  :name, :limit => 256, :null => false


      t.enum :state, :limit => [ :disabled, :active ], :default => :disabled

      t.integer :min_size
      t.integer :max_size
      t.integer :desired_capacity
      t.integer :cooldown
      t.timestamps
    end
  end

  def self.down
    drop_table :auto_scaling_groups
  end
end
