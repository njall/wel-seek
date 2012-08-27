class AddUuidToProtocolVersions < ActiveRecord::Migration
  def self.up
    add_column :protocol_versions, :uuid, :string
  end

  def self.down
    remove_column :protocol_versions,:uuid
  end
end
