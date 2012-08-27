class AddInstitutionToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments,:institution_id,:integer
  end

  def self.down
    remove_column :experiments,:institution_id
  end
end
