class RemoveGenotypePhenotypeFromExperimentOrganisms < ActiveRecord::Migration
  def self.up
    remove_column :experiment_organisms, :genotype_id, :phenotype_id
  end

  def self.down
    add_column :experiment_organisms, :genotype_id, :integer
    add_column :experiment_organisms, :phenotype_id, :integer
  end
end
