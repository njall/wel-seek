class CreateExperimentsExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments_experiments,:id=>false do |t|
      t.integer :experiment_id
      t.integer :experiment_id
    end
  end

  def self.down
    drop_table :experiments_experiments
  end
end
