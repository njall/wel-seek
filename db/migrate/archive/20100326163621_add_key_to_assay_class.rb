class AddKeyToExperimentClass < ActiveRecord::Migration
  def self.up
    add_column :experiment_classes, :key, :string, :limit=>10
  end

  def self.down
    remove_column :experiment_classes,:key
  end
end
