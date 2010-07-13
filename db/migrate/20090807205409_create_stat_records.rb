class CreateStatRecords < ActiveRecord::Migration
  def self.up
    create_table :stat_records do |t|
      t.integer :provider_account_id
      t.datetime :taken_at

      t.timestamps
    end
    add_index :stat_records, [ :provider_account_id, :taken_at ]
  end

  def self.down
    drop_table :stat_records
  end
end
