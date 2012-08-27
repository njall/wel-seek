class AddAssetAttributesToProtocols < ActiveRecord::Migration
  def self.up
    add_column :protocols, :project_id, :integer
    add_column :protocols, :policy_id, :integer
  end

  def self.down
    remove_column :protocols, :project_id
    remove_column :protocols, :policy_id
  end
end
