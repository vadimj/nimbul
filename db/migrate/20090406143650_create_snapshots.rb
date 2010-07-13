class CreateSnapshots < ActiveRecord::Migration
  def self.up
    create_table :snapshots do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :snapshot_id
      t.string :volume_id
      t.string :volume_name
      t.string :status
      t.datetime :start_time
      t.string :progress
      t.boolean :is_enabled, :default => true
      t.string :device

      t.timestamps
    end
	add_index :snapshots, :provider_account_id
	add_index :snapshots, :name
	add_index :snapshots, :snapshot_id
	add_index :snapshots, :volume_id
	add_index :snapshots, :volume_name
  end

  def self.down
    drop_table :snapshots
  end
end
