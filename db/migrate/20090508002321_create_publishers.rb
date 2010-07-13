class CreatePublishers < ActiveRecord::Migration
  def self.up
    create_table :publishers do |t|
      t.string :type
      t.string :description
      t.datetime :last_published_at
      t.datetime :next_publish_at
      t.boolean :is_enabled
      t.string :state
      t.string :state_text

      t.timestamps
    end
  end

  def self.down
    drop_table :publishers
  end
end
