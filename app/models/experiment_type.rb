require 'acts_as_ontology'

class ExperimentType < ActiveRecord::Base

  has_many :experiments
  
  acts_as_ontology    

  def get_child_experiments experiment_type=self
    #TODO: needs unit test
    result = experiment_type.experiments
    experiment_type.children.each do |child|
      result = result | child.experiments
      result = result | get_child_experiments(child) if child.has_children?
    end
    return result
  end
  
  def get_all_descendants experiment_type=self
    result = []
    experiment_type.children.each do |child|
      result << child
      result = result | get_all_descendants(child) if child.has_children?
    end
    return result
  end

  #FIXME: really not happy looking up by title, but will be replaced by BioPortal eventually
  def self.experimental_experiment_type_id
    at=ExperimentType.find_by_title("experiment type").id
  end

  #FIXME: really not happy looking up by title, but will be replaced by BioPortal eventually
  def self.modelling_experiment_type_id
    at=ExperimentType.find_by_title("experiment type").id
  end
 
  private




end
  

