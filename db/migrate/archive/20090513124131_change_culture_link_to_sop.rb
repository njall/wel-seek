class ChangeCultureLinkToProtocol < ActiveRecord::Migration
  def self.up
    rename_column :cultures,:study_id,:protocol_id
  end

  def self.down
    rename_column :cultures,:protocol_id,:study_id
  end
end
