class PopulateMessagingPasswords < ActiveRecord::Migration
  def self.up
    # don't need observers for this migration!
    ProviderAccount.delete_observers
    ProviderAccount.all.map { |pa| pa.regenerate_messaging_password! unless not pa.messaging_password.blank? }
  end

  def self.down
  end
end
