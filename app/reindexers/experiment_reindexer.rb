class ExperimentReindexer < ReindexerObserver

  observe :experiment

  def consequences experiment
    # FIXME: the pending_related_experiments is a temporary solution to finding assets for an experiment, where ExperimentAsset is not visible after_save.
    # This I suspect is due to the transaction not yet being committed - although I would expect this operation to occur within
    # the same transaction. Needs revisiting when there a bit more time.
    experiment.experiment_assets.collect{|a| a.asset} | (experiment.pending_related_assets || [])
  end

end