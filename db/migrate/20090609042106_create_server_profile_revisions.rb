class CreateServerProfileRevisions < ActiveRecord::Migration
  def self.up
    create_table :server_profile_revisions do |t|
      t.integer :server_profile_id
      t.integer :revision, :default => 0
      t.integer :creator_id
      t.text :commit_message
      t.string :image_id
      t.string :ramdisk_id
      t.string :kernel_id
      t.text :startup_script

      t.timestamps
    end
  end

  def self.down
    drop_table :server_profile_revisions
  end
end
