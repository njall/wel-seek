class RenameProtocolToProtocol < ActiveRecord::Migration
  def self.up
    rename_column :sop_specimens, :sop_id, :protocol_id
    rename_column :sop_specimens, :sop_version, :protocol_version
    rename_table :sop_specimens, :protocol_specimens
    rename_table :sop_auth_lookup, :protocol_auth_lookup
    rename_column :sop_versions, :sop_id, :protocol_id
    rename_table :sop_versions, :protocol_versions
  end

  def self.down
    rename_column :protocol_specimens, :protocol_id, :sop_id
    rename_column :protocol_specimens, :protocol_version, :sop_version
    rename_table :protocol_specimens, :sop_specimens
    rename_table :protocol_auth_lookup, :sop_auth_lookup
    rename_column :protocol_versions, :protocol_id, :sop_id
    rename_table :protocol_versions, :sop_versions
  end
end
