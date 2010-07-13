class ModifyDefaultStatusForMessages < ActiveRecord::Migration
  def self.up
    change_column :messages, :status, :string, :default => 'ok'
  end

  def self.down
    change_column :messages, :status, :string, :default => 'unknown'
  end
end
