class CreateExperimentTypes < ActiveRecord::Migration
  def self.up
    create_table :experiment_types do |t|
      t.string :title
      t.string :parent_experiment_type_id
      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_types
  end
end
