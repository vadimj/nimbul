class FixAutoScalingTriggers < ActiveRecord::Migration
  def self.up
	remove_column :auto_scaling_triggers, :lower_breach_scale_increment 
	add_column :auto_scaling_triggers, :lower_breach_scale_increment, :string 
	remove_column :auto_scaling_triggers, :upper_breach_scale_increment 
	add_column :auto_scaling_triggers, :upper_breach_scale_increment, :string
	remove_column :auto_scaling_triggers, :state 
	add_column :auto_scaling_triggers, :state, :string,
	  :default => :disabled
	remove_column :auto_scaling_triggers, :measure_name 
	add_column :auto_scaling_triggers, :measure_name, :string,
      :default => :CPUUtilization
	remove_column :auto_scaling_triggers, :statistic 
	add_column :auto_scaling_triggers, :statistic, :string,
	  :default => :Average
	remove_column :auto_scaling_triggers, :unit
	add_column :auto_scaling_triggers, :unit, :string
  end

  def self.down
	remove_column :auto_scaling_triggers, :lower_breach_scale_increment 
	add_column :auto_scaling_triggers, :lower_breach_scale_increment, :integer 
	remove_column :auto_scaling_triggers, :upper_breach_scale_increment 
	add_column :auto_scaling_triggers, :upper_breach_scale_increment, :integer
	remove_column :auto_scaling_triggers, :state 
	add_column :auto_scaling_triggers, :state, :enum,
	  :limit => [ :disabled, :active ],
	  :default => :disabled
	remove_column :auto_scaling_triggers, :measure_name 
	add_column :auto_scaling_triggers, :measure_name, :enum,
	  :limit => [ :CPUUtilization, :NetworkIn, :NetworkOut, :DiskWriteOps, :DiskReadBytes, :DiskReadOps, :DiskWriteBytes ],
      :default => :CPUUtilization
	remove_column :auto_scaling_triggers, :statistic 
	add_column :auto_scaling_triggers, :statistic, :enum,
	  :limit => [ :Minimum, :Maximum, :Sum, :Average ],
	  :default => :Average
	remove_column :auto_scaling_triggers, :unit
	add_column :auto_scaling_triggers, :unit, :enum,
	  :limit => [ :None, :Seconds, :Percent, :Bytes, :Bits, :Count, :"Bytes/Second", :"Bits/Second", :"Count/Second" ],
	  :default => :None
  end
end