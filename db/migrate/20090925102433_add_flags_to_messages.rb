class AddFlagsToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :flags, :integer
  end

  def self.down
    remove_column :messages, :flags
  end
end
