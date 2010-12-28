require 'digest/md5'
class UserKey < ActiveRecord::Base
    belongs_to :user
    validates_presence_of :public_key
    
    attr_accessor :hash_of_public_key
    
    def hash_of_public_key
        return self.class.hash_of(self[:public_key])
    end
    
    def self.hash_of(value)
        return value if value.blank?
        return Digest::MD5.hexdigest(value.split(/\s+/).join(' ').chomp)
    end
end
