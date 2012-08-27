class CreateExperimentsStudies < ActiveRecord::Migration
  def self.up
    create_table :experiments_studies,:id=>false do |t|
      t.integer :experiment_id
      t.integer :study_id
    end
  end

  def self.down
    drop_table :experiments_studies
  end
  
end
