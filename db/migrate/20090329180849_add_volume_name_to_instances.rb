class AddVolumeNameToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :volume_name, :string
  end

  def self.down
    remove_column :instances, :volume_name
  end
end
