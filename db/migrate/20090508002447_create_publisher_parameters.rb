class CreatePublisherParameters < ActiveRecord::Migration
  def self.up
    create_table :publisher_parameters do |t|
      t.integer :publisher_id
      t.string :name
      t.string :description
      t.string :value
      t.string :control_type

      t.timestamps
    end
    add_index :publisher_parameters, :publisher_id
  end

  def self.down
    drop_table :publisher_parameters
  end
end
