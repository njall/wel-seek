class AddOtherCreatorsToProtocols < ActiveRecord::Migration
  def self.up
    add_column :protocols, :other_creators, :text
    add_column :protocol_versions, :other_creators, :text
  end

  def self.down
    remove_column :protocols, :other_creators
    remove_column :protocol_versions, :other_creators
  end
end
