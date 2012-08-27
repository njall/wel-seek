class ExperimentClass < ActiveRecord::Base

  #this returns an instance of ExperimentClass according to one of the types "experimental" or "modelling"
  #if there is not a match nil is returned
  def self.for_type type
    keys={"experimental"=>"EXP","modelling"=>"MODEL"}
    return ExperimentClass.find_by_key(keys[type])
  end
end
