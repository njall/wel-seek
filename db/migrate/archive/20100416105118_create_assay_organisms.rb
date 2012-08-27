class CreateExperimentOrganisms < ActiveRecord::Migration
  def self.up
    create_table :experiment_organisms do |t|
      t.integer :experiment_id
      t.integer :organism_id
      t.integer :culture_growth_type_id
      t.integer :strain_id
      t.integer :phenotype_id
      t.integer :genotype_id

      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_organisms
  end
end
