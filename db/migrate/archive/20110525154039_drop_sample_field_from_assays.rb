class DropSampleFieldFromExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments,:sample_id
  end

  def self.down
    add_column :experiments,:sample_id,:integer
  end
end
