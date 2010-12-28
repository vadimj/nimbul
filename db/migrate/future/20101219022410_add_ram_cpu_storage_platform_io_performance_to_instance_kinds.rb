class AddRamCpuStoragePlatformIoPerformanceToInstanceKinds < ActiveRecord::Migration
  def self.up
    add_column :instance_kinds, :ram_mb, :integer, :default => 0
    add_column :instance_kinds, :cpu_cores, :integer, :default => 0
    add_column :instance_kinds, :cpu_units, :integer, :default => 0
    add_column :instance_kinds, :storage_gb, :integer, :default => 0
    add_column :instance_kinds, :io_performance, :string
    add_column :instance_kinds, :platform_bit, :integer, :default => 32
  end

  def self.down
    remove_column :instance_kinds, :io_performance
    remove_column :instance_kinds, :storage_gb
    remove_column :instance_kinds, :cpu_units
    remove_column :instance_kinds, :cpu_cores
    remove_column :instance_kinds, :ram_mb
    remove_column :instance_kinds, :platform_bit
  end
end
