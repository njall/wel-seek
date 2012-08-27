class RemoveCultureGrowthFromExperiment < ActiveRecord::Migration
  def self.up
    remove_column(:experiments, :culture_growth_type_id)
  end

  def self.down
    add_column :experiments,:culture_growth_type_id,:integer
  end
end
