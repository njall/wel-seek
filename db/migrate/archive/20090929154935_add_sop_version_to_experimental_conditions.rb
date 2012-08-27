class AddProtocolVersionToExperimentalConditions < ActiveRecord::Migration

  def self.up
    add_column :experimental_conditions, :protocol_version, :integer
  end

  def self.down
    remove_column :experimental_conditions, :protocol_version
  end
  
end
