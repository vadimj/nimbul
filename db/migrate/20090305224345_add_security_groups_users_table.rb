class AddSecurityGroupsUsersTable < ActiveRecord::Migration
  def self.up
    #generate the join table
    create_table "security_groups_users", :id => false do |t|
      t.integer "security_group_id", "user_id"
    end
    add_index "security_groups_users", "security_group_id"
    add_index "security_groups_users", "user_id"
  end

  def self.down
    drop_table "security_groups_users"
  end
end
