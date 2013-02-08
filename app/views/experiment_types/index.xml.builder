xml.instruct! :xml

xml.tag! "experiment_types",xlink_attributes(uri_for_collection("experiment_types", :params => params)),
xml_root_attributes,
         :resourceType => "ExperimentTypes" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@experiment_types,:parent_xml => xml}
  
  
end