is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "experiment",
core_xlink(experiment).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>experiment}
  parent_xml.tag! "experiment_class",core_xlink(experiment.experiment_class)
  parent_xml.tag! "experiment_type",core_xlink(experiment.experiment_type)
  
  unless experiment.is_modelling?
    parent_xml.tag! "technology_type",core_xlink(experiment.technology_type)
  else
    parent_xml.tag! "technology_type",{"xsi:nil"=>true}
  end
  
  if (is_root)    
    parent_xml.tag! "experiment_organisms" do
      experiment.experiment_organisms.each do |ao|
        parent_xml.tag! "experiment_organism" do
          api_partial parent_xml,ao.organism
          api_partial parent_xml,ao.strain if ao.strain
          parent_xml.tag! "culture_growth",core_xlink(ao.culture_growth_type) if ao.culture_growth_type          
        end      
      end      
    end
    
    if experiment.is_modelling?
      experiment_data_relationships_xml parent_xml,experiment
    end
    
    associated_resources_xml parent_xml,experiment
    
  end
  
end