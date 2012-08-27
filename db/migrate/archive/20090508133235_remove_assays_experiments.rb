class RemoveExperimentsExperiments < ActiveRecord::Migration
  def self.up
    drop_table :experiments_experiments
  end

  def self.down
    create_table "experiments_experiments", :id => false do |t|
    t.integer "experiment_id"
    t.integer "experiment_id"
  end
  end
end
