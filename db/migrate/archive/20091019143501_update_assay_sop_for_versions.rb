class UpdateExperimentProtocolForVersions < ActiveRecord::Migration
  def self.up
    select_all('SELECT * FROM experiments_protocols').each do |values|
      experiment_id=values["experiment_id"]
      protocol_id=values["protocol_id"]
      protocol=Protocol.find(protocol_id)
      
      a=ExperimentAsset.new(:experiment_id=>experiment_id,:asset_id=>protocol.asset.id,:version=>protocol.version)
      a.save
    end
  end

  def self.down
    select_all('SELECT * FROM experiments_protocols').each do |values|
      experiment_id=values["experiment_id"]
      protocol_id=values["protocol_id"]
      protocol=Protocol.find(protocol_id)
      a=ExperimentAsset.find(:first,:conditions=>["experiment_id=? and asset_id=?",experiment_id,protocol.asset.id])
      a.destroy unless a.nil?
    end
  end
end
