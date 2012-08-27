class AddOwnerToExperiment < ActiveRecord::Migration
  def self.up
    add_column :experiments, :owner_id, :integer
  end

  def self.down
    remove_column :experiments, :owner_id
  end
end
