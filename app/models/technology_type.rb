require 'acts_as_ontology'

class TechnologyType < ActiveRecord::Base

  has_many :experiments

  acts_as_ontology

  def get_child_experiments technology_type=self
    #TODO: needs unit test
    #TODO: make Experiment independant, and move some of this to acts_as_ontology
    result = technology_type.experiments
    technology_type.children.each do |child|
      result = result | child.experiments
      result = result | get_child_experiments(child) if child.has_children?
    end
    return result
  end
 
  def get_all_descendants technology_type=self
    result = []
    technology_type.children.each do |child|
      result << child
      result = result | get_all_descendants(child) if child.has_children?
    end
    return result
  end

end
