xml.instruct! :xml

xml.tag! "experiments",xlink_attributes(uri_for_collection("experiments", :params => params)),
xml_root_attributes,
         :resourceType => "Experiments" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@experiments,:parent_xml => xml}
  
  
end