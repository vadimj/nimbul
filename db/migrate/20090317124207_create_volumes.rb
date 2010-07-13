class CreateVolumes < ActiveRecord::Migration
  def self.up
    create_table :volumes do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :volume_id
      t.string :snapshot_id
      t.datetime :create_time
      t.integer :size
      t.string :availability_zone
      t.string :status

      t.timestamps
    end
    add_index :volumes, :name
    add_index :volumes, :volume_id
    add_index :volumes, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :volumes
  end
end
