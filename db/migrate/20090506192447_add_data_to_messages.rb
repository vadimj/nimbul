class AddDataToMessages < ActiveRecord::Migration
  def self.up
    remove_column :messages, :command
    remove_column :messages, :args
    add_column :messages, :message, :string
    add_column :messages, :data, :text
  end

  def self.down
    add_column :messages, :command, :string
    add_column :messages, :args, :string
    remove_column :messages, :message
    remove_column :messages, :data
  end
end
