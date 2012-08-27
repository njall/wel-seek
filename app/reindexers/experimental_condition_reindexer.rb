class ExperimentalConditionReindexer < ReindexerObserver
  observe :experimental_condition

  def consequences experimental_condition
    [experimental_condition.protocol]
  end
  
end