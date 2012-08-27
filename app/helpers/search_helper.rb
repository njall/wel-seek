module SearchHelper
  
  def search_type_options
    search_type_options = ["All", "Institutions", "People", "Projects"]
    search_type_options |= Seek::Util.user_creatable_types.collect{|c| [(c.name.underscore.humanize == "Protocol" ? "Protocol" : c.name.underscore.humanize.pluralize),c.name.underscore.pluralize] }
    return search_type_options
  end
    
  def saved_search_image_tag saved_search
    tiny_image = image_tag "/images/famfamfam_silk/find.png", :style => "padding: 11px; border:1px solid #CCBB99;background-color:#FFFFFF;"
    return link_to_draggable(tiny_image, saved_search_path(saved_search.id), :title=>tooltip_title_attrib("Search: #{saved_search.search_query} (#{saved_search.search_type})"),:class=>"saved_search", :id=>"sav_#{saved_search.id}")
  end
  
end
