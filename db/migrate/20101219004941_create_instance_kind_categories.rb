class CreateInstanceKindCategories < ActiveRecord::Migration
  def self.up
    create_table :instance_kind_categories do |t|
      t.integer :provider_id
      t.string :name
      t.string :description
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :instance_kind_categories
  end
end
