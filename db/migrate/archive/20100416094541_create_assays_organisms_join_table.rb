class CreateExperimentsOrganismsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :experiments_organisms,:id=>false do |t|
      t.integer :experiment_id
      t.integer :organism_id
    end
  end

  def self.down
    drop_table :experiments_organisms
  end
end
