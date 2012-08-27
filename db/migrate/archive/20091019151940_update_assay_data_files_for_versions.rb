class UpdateExperimentDataFilesForVersions < ActiveRecord::Migration
  def self.up
    select_all('SELECT * FROM created_datas').each do |values|
      experiment_id=values["experiment_id"]
      df_id=values["data_file_id"]
      df=DataFile.find(df_id)

      a=ExperimentAsset.new(:experiment_id=>experiment_id,:asset_id=>df.asset.id,:version=>df.version)
      a.save
    end
  end

  def self.down
    select_all('SELECT * FROM created_datas').each do |values|
      experiment_id=values["experiment_id"]
      df_id=values["data_file_id"]
      df=DataFile.find(df_id)

      a=ExperimentAsset.find(:first,:conditions=>["experiment_id=? and asset_id=?",experiment_id,df.asset.id])
      a.destroy unless a.nil?
    end
  end
end
