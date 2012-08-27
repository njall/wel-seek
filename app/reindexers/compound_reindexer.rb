class CompoundReindexer < ReindexerObserver
  observe :compound

  def consequences compound
    compound.data_files | compound.protocols
  end
  
end
