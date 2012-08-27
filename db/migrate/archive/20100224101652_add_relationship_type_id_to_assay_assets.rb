class AddRelationshipTypeIdToExperimentAssets < ActiveRecord::Migration
  def self.up
    add_column :experiment_assets, :relationship_type_id, :integer
  end

  def self.down
    remove_column :experiment_assets, :relationship_type_id
  end
end
