class ExperimentTypesEdges < ActiveRecord::Migration
  def self.up
    create_table :experiment_types_edges,:id=>false do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end

  def self.down
    drop_table :experiment_types_edges
  end
end
