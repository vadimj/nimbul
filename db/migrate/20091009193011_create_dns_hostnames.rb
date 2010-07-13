class CreateDnsHostnames < ActiveRecord::Migration
  def self.up
    create_table :dns_hostnames do |t|
      t.primary_key :id
      t.string :name, :limit => 64, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :dns_hostnames
  end
end
