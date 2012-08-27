class CreateProtocolsSpecimens < ActiveRecord::Migration
  def self.up
    create_table :protocol_specimens do |t|
      t.integer :specimen_id
      t.integer :protocol_id
      t.integer :protocol_version
    end
  end

  def self.down
    drop_table :protocol_specimens
  end
end
