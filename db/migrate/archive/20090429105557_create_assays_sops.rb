class CreateExperimentsProtocols < ActiveRecord::Migration
  def self.up
    create_table :experiments_protocols,:id=>false do |t|
      t.integer :experiment_id
      t.integer :protocol_id
    end
  end

  def self.down
    drop_table :experiments_protocols
  end
end
