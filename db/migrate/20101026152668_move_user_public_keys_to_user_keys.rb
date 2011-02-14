require 'pp'
class MoveUserPublicKeysToUserKeys < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      unless user.public_key.blank?
        user_key = user.user_keys.create({ :public_key => user.public_key })
      end
    end
  end

  def self.down
    User.find(:all).each do |user|
      if user.user_keys and user.user_keys.size > 0 and user.user_keys.first
        public_key = user.user_keys.first.public_key
        unless public_key.blank?
          user.update_attribute(:public_key, public_key) 
        end
      end
    end
  end
end
