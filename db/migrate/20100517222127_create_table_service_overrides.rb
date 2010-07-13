class CreateTableServiceOverrides < ActiveRecord::Migration
  def self.up
    create_table :service_overrides do |t|
      t.primary_key :id
      t.integer :service_provider_id, :null => false
      t.string  :target_type, :limit => 100, :null => false
      t.integer :target_id,   :null => false
      t.timestamps
    end

    add_index :service_overrides, :service_provider_id
    add_index :service_overrides, [:service_provider_id, :target_type, :target_id ], :unique => true, :name => :idx_spid_ttype_tid
  end

  def self.down
    drop_table :service_overrides
  end
end
