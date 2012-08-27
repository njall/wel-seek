class RemoveOrganismFromExperiment < ActiveRecord::Migration
  def self.up
    remove_column(:experiments, :organism_id)
  end

  def self.down
    add_column :experiments, :organism_id, :integer
  end
end
