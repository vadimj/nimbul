class CreateInstanceTypeCategories < ActiveRecord::Migration
  def self.up
    create_table :instance_type_categories do |t|
      t.integer :provider_id
      t.string :name
      t.string :description
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :instance_type_categories
  end
end
