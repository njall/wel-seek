class CreateExperimentsSamples < ActiveRecord::Migration
  def self.up
    create_table :experiments_samples, :id => false do |t|
      t.integer :experiment_id
      t.integer :sample_id
    end
  end

  def self.down
    drop_table :experiments_samples
  end
end
