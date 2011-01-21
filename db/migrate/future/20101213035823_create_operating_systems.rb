class CreateOperatingSystems < ActiveRecord::Migration
  def self.up
    create_table :operating_systems do |t|
      t.integer :provider_id
      t.string :name
      t.string :description
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :operating_systems
  end
end
