class CreateServerProfileRevisionParameters < ActiveRecord::Migration
  def self.up
    create_table :server_profile_revision_parameters do |t|
      t.integer :server_profile_revision_id
      t.integer :position
      t.string :type
      t.string :name
      t.text :value
      t.boolean :is_protected, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :server_profile_revision_parameters
  end
end
