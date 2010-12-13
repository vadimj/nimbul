class CreateInstanceKinds < ActiveRecord::Migration
  def self.up
    create_table :instance_kinds do |t|
      t.integer :instance_type_category_id
      t.string :code_name
      t.string :name
      t.text :description
      t.boolean :is_default
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :instance_kinds
  end
end
