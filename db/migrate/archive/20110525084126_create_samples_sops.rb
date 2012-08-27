class CreateSamplesProtocols < ActiveRecord::Migration
  def self.up
    create_table :sample_protocols do |t|
      t.integer :sample_id
      t.integer :protocol_id
      t.integer :protocol_version
    end
  end

  def self.down
    drop_table :sample_protocols
  end
end
