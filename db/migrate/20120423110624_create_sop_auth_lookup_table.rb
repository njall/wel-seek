class CreateProtocolAuthLookupTable < ActiveRecord::Migration
  def self.up
    create_table :protocol_auth_lookup, :id=>false do |t|
      t.integer :person_id
      t.integer :asset_id
      t.boolean :can_view, :default=>false
      t.boolean :can_manage, :default=>false
      t.boolean :can_edit, :default=>false
      t.boolean :can_download, :default=>false
      t.boolean :can_delete, :default=>false
    end
    add_index :protocol_auth_lookup, [:person_id,:can_view]
  end

  def self.down
    drop_table :protocol_auth_lookup
  end
end
