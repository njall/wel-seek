xml.instruct! :xml

xml.tag! "protocols",xlink_attributes(uri_for_collection("protocols", :params => params)),
xml_root_attributes,
         :resourceType => "Protocols" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@protocols,:parent_xml => xml}
  
  
end