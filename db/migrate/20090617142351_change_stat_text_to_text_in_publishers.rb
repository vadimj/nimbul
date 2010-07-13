class ChangeStatTextToTextInPublishers < ActiveRecord::Migration
  def self.up
    remove_column :publishers, :state_text
    add_column :publishers, :state_text, :text
  end

  def self.down
    remove_column :publishers, :state_text
    add_column :publishers, :state_text, :string
  end
end
