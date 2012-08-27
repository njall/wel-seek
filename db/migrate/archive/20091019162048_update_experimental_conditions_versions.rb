class UpdateExperimentalConditionsVersions < ActiveRecord::Migration
  def self.up
    select_all("select * from experimental_conditions").each do |values|
      protocol_id=values["protocol_id"]
      protocol=Protocol.find(protocol_id)
      update "update experimental_conditions set protocol_version=#{protocol.version} where id=#{values["id"]}"
    end
  end

  def self.down
  end
end
