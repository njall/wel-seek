class LinkCultureGrowthTypeToExperiment < ActiveRecord::Migration
  def self.up
    add_column :experiments, :culture_growth_type_id, :integer, :default=>0
  end

  def self.down
    remove_column :experiments, :culture_growth_type_id
  end
end
