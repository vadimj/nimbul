class CreateServerProfiles < ActiveRecord::Migration
  def self.up
    create_table :server_profiles do |t|
      t.string :name
      t.text :description
      t.integer :creator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :server_profiles
  end
end
