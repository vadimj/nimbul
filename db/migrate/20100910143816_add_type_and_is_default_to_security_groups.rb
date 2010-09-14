class AddTypeAndIsDefaultToSecurityGroups < ActiveRecord::Migration
  def self.up
    add_column :security_groups, :type, :string
    add_column :security_groups, :is_default, :boolean
  end

  def self.down
    remove_column :security_groups, :is_default
    remove_column :security_groups, :type
  end
end
