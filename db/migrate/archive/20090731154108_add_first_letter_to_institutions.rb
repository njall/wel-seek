class AddFirstLetterToInstitutions < ActiveRecord::Migration
  def self.up
    add_column :institutions,:first_letter,:string,:limit => 1
  end

  def self.down
    remove_column :institutions,:first_letter
  end

end
