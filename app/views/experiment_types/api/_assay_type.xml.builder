is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "experiment_type",
core_xlink(experiment_type).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>experiment_type}
  
  if (is_root)
    parent_child_elements parent_xml,experiment_type
  end
  
end

