class SynonymReindexer < ReindexerObserver

  observe :synonym

  def consequences synonym
    res = synonym.data_files | synonym.protocols
    res = res | synonym.substance.data_files if synonym.substance.respond_to?(:data_files)
    res = res | synonym.substance.protocols if synonym.substance.respond_to?(:protocols)
    res.uniq
  end

end