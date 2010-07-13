class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :provider_account_id
      t.string :type
      t.string :message_id
      t.string :recipient
      t.string :sender
      t.string :handler
      t.string :command
      t.string :args
      t.string :state, :default => 'pending'
      t.timestamp :sent_at
      t.timestamp :received_at

      t.timestamps
    end
    add_index :messages, [:type]
    add_index :messages, [:provider_account_id, :type]
    add_index :messages, [:provider_account_id, :state]
  end

  def self.down
    drop_table :messages
  end
end
