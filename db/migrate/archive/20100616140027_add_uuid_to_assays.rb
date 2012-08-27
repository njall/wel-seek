class AddUuidToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :uuid, :string
  end

  def self.down
    remove_column :experiments,:uuid
  end
end
