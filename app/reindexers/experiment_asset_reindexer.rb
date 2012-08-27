class ExperimentAssetReindexer < ReindexerObserver

  observe :experiment_asset

  def consequences experiment_asset
    experiment_asset.asset
  end

end