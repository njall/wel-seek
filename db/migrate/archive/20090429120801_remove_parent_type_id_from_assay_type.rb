class RemoveParentTypeIdFromExperimentType < ActiveRecord::Migration
  
  def self.up
    remove_column(:experiment_types, :parent_experiment_type_id)
  end

  def self.down
    add_column :experiment_types, :parent_experiment_type_id, :string
  end

end
