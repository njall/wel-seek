class DropExperimentFieldInExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments, :experiment_id
  end

  def self.down
    add_column :experiments, :experiment_id, :integer
  end
end
