class AddAssetAttributesToProtocolVersions < ActiveRecord::Migration
  def self.up
    add_column :protocol_versions, :project_id, :integer
    add_column :protocol_versions, :policy_id, :integer
  end

  def self.down
    remove_column :protocol_versions, :project_id
    remove_column :protocol_versions, :policy_id
  end
end
