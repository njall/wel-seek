class ProtocolSpecimen < ActiveRecord::Base
  belongs_to :specimen
  belongs_to :protocol

  before_save :check_version
  #always returns the correct versioned asset (e.g Protocol::Version) according to the stored version, or latest version if version is nil
  def versioned_asset
    s=self.protocol
    s=s.parent if s.class.name.end_with?("::Version")
    if version.nil?
      s.latest_version
    else
      s.find_version(protocol_version)
    end
  end

  def check_version
    if protocol_version.nil? && !protocol.nil? && protocol.class.name.end_with?("::Version")
      self.protocol_version=protocol.version
    end
  end
end