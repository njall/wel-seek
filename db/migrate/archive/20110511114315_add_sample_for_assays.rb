class AddSampleForExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments,:sample_id,:integer
  end

  def self.down
    remove_column :experiments,:sample_id
  end
end
