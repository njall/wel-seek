class ExperimentAsset < ActiveRecord::Base
  
  belongs_to :asset, :polymorphic => true
  belongs_to :experiment
  
  belongs_to :relationship_type
  
  before_save :check_version
  
  #always returns the correct versioned asset (e.g Protocol::Version) according to the stored version, or latest version if version is nil
  def versioned_asset
    a=self.asset
    a=a.parent if a.class.name.end_with?("::Version")
    if version.nil?
      a.latest_version
    else
      a.find_version(version)
    end    
  end
  
  def check_version
    if version.nil? && !asset.nil? && asset.class.name.end_with?("::Version")
      self.version=asset.version
    end
  end
  
end
