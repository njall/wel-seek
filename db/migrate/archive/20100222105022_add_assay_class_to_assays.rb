class AddExperimentClassToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :experiment_class_id, :integer
  end

  def self.down
    remove_column :experiments, :experiment_class_id
  end
end
