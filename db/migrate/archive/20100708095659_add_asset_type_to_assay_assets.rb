class AddAssetTypeToExperimentAssets < ActiveRecord::Migration
  def self.up
    add_column :experiment_assets, :asset_type, :string
  end

  def self.down
    remove_column :experiment_assets, :asset_type
  end
end
