class LinkTechnologyTypeToExperiment < ActiveRecord::Migration
  
  def self.up
    add_column :experiments, :technology_type_id, :integer
  end

  def self.down
    remove_column :experiments,:technology_type_id
  end
  
end
