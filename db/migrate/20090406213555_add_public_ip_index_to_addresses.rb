class AddPublicIpIndexToAddresses < ActiveRecord::Migration
  def self.up
	add_index :addresses, :public_ip
  end

  def self.down
  end
end
