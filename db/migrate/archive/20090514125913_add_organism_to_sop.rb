class AddOrganismToProtocol < ActiveRecord::Migration
  def self.up
    add_column :protocols, :organism_id, :integer
  end

  def self.down
    remove_column :protocols,:organism_id
  end
end
