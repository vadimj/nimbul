require 'digest/md5'
class UserKey < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :public_key
  validates_uniqueness_of :hash_of_public_key, :scope => :user_id
  
  before_save :set_hash_of_public_key

  attr_accessor :should_destroy
  def should_destroy?
    should_destroy.to_i == 1
  end
    
  # before filter
  def set_hash_of_public_key
    self.hash_of_public_key = self.class.hash_of(public_key)
  end
  
  def self.hash_of(value)
    return if value.blank?
    return Digest::MD5.hexdigest(value.split(/\s+/).join(' ').chomp)
  end
end
