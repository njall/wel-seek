class RemoveExperimentsProtocols < ActiveRecord::Migration
  def self.up
    drop_table(:experiments_protocols)
  end

  def self.down
    create_table "experiments_protocols", :id => false do |t|
    t.integer "experiment_id"
    t.integer "protocol_id"
  end
  end
end
