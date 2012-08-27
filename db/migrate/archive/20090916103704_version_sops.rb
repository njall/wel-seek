class VersionProtocols < ActiveRecord::Migration

  def self.up
    Protocol.create_versioned_table
    def Protocol.record_timestamps
      false
    end
    Protocol.find(:all).each do |s|
      s.save!      
    end

  end

  def self.down
    Protocol.drop_versioned_table
  end
end
