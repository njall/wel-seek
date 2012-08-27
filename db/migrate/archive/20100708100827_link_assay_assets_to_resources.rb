require 'save_without_timestamping'

#In case Asset is gone
class Asset < ActiveRecord::Base 
  belongs_to :resource, :polymorphic => true
end

#Needed so we can use model logic
class ExperimentAsset < ActiveRecord::Base
  belongs_to :asset
end

class LinkExperimentAssetsToResources < ActiveRecord::Migration
  def self.up
    count = 0
    total = ExperimentAsset.count
    ExperimentAsset.all.each do |experiment_asset|
      resource = experiment_asset.asset.resource
      experiment_asset.asset_id = resource.id
      experiment_asset.asset_type = resource.class.name
      if experiment_asset.save_without_timestamping
        count += 1
      end
    end
    
    puts "#{count}/#{total} ExperimentAssets updated successfully."
  end

  def self.down
    #There's not really a way to undo this!
  end
end
