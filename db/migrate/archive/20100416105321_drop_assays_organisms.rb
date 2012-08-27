class DropExperimentsOrganisms < ActiveRecord::Migration
  def self.up
    drop_table :experiments_organisms
  end
  
  def self.down
    create_table :experiments_organisms,:id=>false do |t|
      t.integer :experiment_id
      t.integer :organism_id
    end
  end
  
end
