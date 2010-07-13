class AddTimeoutAtColumnToOperations < ActiveRecord::Migration
  def self.up
	add_column :operations, :timeout_at, :datetime
  end

  def self.down
	remove_column :operations, :timeout_at
  end
end
