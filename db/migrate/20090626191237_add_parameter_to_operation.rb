class AddParameterToOperation < ActiveRecord::Migration
  def self.up
    add_column :operations, :parameter, :string
  end

  def self.down
    remove_column :operations, :parameter
  end
end
