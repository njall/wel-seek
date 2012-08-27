class AddUuidToProtocols < ActiveRecord::Migration
  def self.up
    add_column :protocols, :uuid, :string
  end

  def self.down
    remove_column :protocols,:uuid
  end
end
