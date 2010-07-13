class AddProgressAndAttachmentStatusToCloudResources < ActiveRecord::Migration
  def self.up
    add_column :cloud_resources, :progress, :string
    add_column :cloud_resources, :attachment_state, :string
    add_column :cloud_resources, :attach_time, :string
    add_column :cloud_resources, :start_time, :datetime
    add_index :cloud_resources, [ :provider_account_id, :parent_cloud_id ]
  end

  def self.down
    remove_column :cloud_resources, :attachment_state
    remove_column :cloud_resources, :progress
    remove_column :cloud_resources, :attach_time
    remove_column :cloud_resources, :start_time
  end
end
