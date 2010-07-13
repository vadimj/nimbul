class CreateAutoScalingTriggers < ActiveRecord::Migration
  def self.up
    create_table :auto_scaling_triggers do |t|
      t.primary_key :id
      t.integer :auto_scaling_group_id
      t.string :name, :limit => 64, :null => false

      t.enum :state, :limit => [ :disabled, :active ], :default => :disabled
      
      t.enum :measure_name,
        :limit => [ :CPUUtilization, :NetworkIn, :NetworkOut, :DiskWriteOps, :DiskReadBytes, :DiskReadOps, :DiskWriteBytes ],
        :default => :CPUUtilization
      t.enum :statistic, :limit => [ :Minimum, :Maximum, :Sum, :Average ], :default => :Average
      t.integer :period
      t.enum :unit, :limit => [ :None, :Seconds, :Percent, :Bytes, :Bits, :Count, :"Bytes/Second", :"Bits/Second", :"Count/Second" ], :default => :None

      t.string :lower_threshold
      t.integer :lower_breach_scale_increment
      t.string :upper_threshold
      t.integer :upper_breach_scale_increment
      t.integer :breach_duration

      t.timestamps
    end
  end

  def self.down
    drop_table :auto_scaling_triggers
  end
end
