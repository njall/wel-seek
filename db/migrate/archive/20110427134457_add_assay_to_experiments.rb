class AddExperimentToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments,:experiment_id,:integer
  end

  def self.down
    remove_column :experiments,:experiment_id
  end
end
