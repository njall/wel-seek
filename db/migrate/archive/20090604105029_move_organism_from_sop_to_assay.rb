class MoveOrganismFromProtocolToExperiment < ActiveRecord::Migration
  def self.up
    remove_column :protocols,:organism_id
    add_column :experiments,:organism_id,:integer
  end

  def self.down
    remove_column :experiments,:organism_id
    add_column :protocols,:organism_id,:integer
  end
end
