class CreateInstanceListReaders < ActiveRecord::Migration
  def self.up
    create_table :instance_list_readers do |t|
      t.integer :provider_account_id
      t.string :type
      t.string :name
      t.string :email
      t.string :s3_user_id
      t.string :permission
      t.boolean :is_owner
      t.boolean :is_enabled

      t.timestamps
    end
    add_index :instance_list_readers, :provider_account_id
    add_index :instance_list_readers, :s3_user_id
  end

  def self.down
    drop_table :instance_list_readers
  end
end
