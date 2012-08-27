module ProtocolsHelper

  def authorised_protocols projects=nil
    authorised_assets(Protocol,projects)
  end    

end