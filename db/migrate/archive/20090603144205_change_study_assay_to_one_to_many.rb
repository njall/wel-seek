class ChangeStudyExperimentToOneToMany < ActiveRecord::Migration
  def self.up
    add_column :experiments, :study_id, :integer
    drop_table :experiments_studies
  end

  def self.down
    remove_column :experiments,:study_id
    create_table :experiments_studies, :id => false do |t|
      t.integer :experiment_id
      t.integer :study_id
    end
  end
end
