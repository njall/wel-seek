module AssetsHelper

  def request_request_label resource
    icon_filename=icon_filename_for_key("message")
    resource_type=text_for_resource(resource)
    image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}"
  end

  #returns all the classes for models that return true for is_asset?
  def asset_model_classes
    @@asset_model_classes ||= Seek::Util.persistent_classes.select do |c|
      !c.nil? && c.is_asset?
    end
  end

  def publishing_item_param item
    "publish[#{item.class.name}][#{item.id}]"
  end

  def text_for_resource resource_or_text
    if resource_or_text.is_a?(String)
      text = resource_or_text
    elsif resource_or_text.kind_of?(Specimen)
      text = CELL_CULTURE_OR_SPECIMEN
    else
      text = resource_or_text.class.name
    end
    text.underscore.humanize
  end

  def resource_version_selection versioned_resource, displayed_resource_version
    versions=versioned_resource.versions.reverse
    disabled=versions.size==1
    options=""
    versions.each do |v|
      options << "<option value='#{url_for(:id=>versioned_resource, :version=>v.version)}'"
      options << " selected='selected'" if v.version==displayed_resource_version.version
      options << "> #{v.version.to_s} #{versioned_resource.describe_version(v.version)} </option>"
    end
    select_tag(:resource_versions,
               options,
               :disabled=>disabled,
               :onchange=>"showResourceVersion($('show_version_form'));"
    ) + "<form id='show_version_form' onsubmit='showResourceVersion(this); return false;'></form>".html_safe
  end

  def resource_title_draggable_avatar resource
    icon=""
    image=nil

    if resource.avatar_key
      image=image resource.avatar_key, {}
    elsif resource.use_mime_type_for_avatar?
      image = image file_type_icon_key(resource), {}
    end

    icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource))) unless image.nil?
    icon
  end

  def get_original_model_name(model)
    class_name = model.class.name
    if class_name.end_with?("::Version")
      class_name = class_name.split("::")[0]
    end
    class_name
  end

  #Changed these so they can cope with non-asset things such as studies, experiments etc.
  def download_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = polymorphic_path(resource.parent, :version=>resource.version, :action=>:download)
    else
      path = polymorphic_path(resource, :action=>:download)
    end
    return path
  end

  #returns true if this permission should not be able to be removed from custom permissions
  #it indicates that this is the management rights for the current user.
  #the logic is that true is returned if the current_user is the contributor of this permission, unless that person is also the contributor of the asset
  def prevent_manager_removal(resource, permission)
    permission.access_type==Policy::MANAGING && permission.contributor==current_user.person && resource.contributor != current_user
  end

  def show_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = polymorphic_path(resource.parent, :version=>resource.version)
    else
      path = polymorphic_path(resource)
    end
    return path
  end

  def edit_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = edit_polymorphic_path(resource.parent)
    else
      path = edit_polymorphic_path(resource)
    end
    return path
  end

  #Get a hash of appropriate related resources for the given resource. Also returns a hash of hidden resources
  def get_related_resources(resource, limit=nil)
    name = resource.class.name.split("::")[0]

    related = {"Person" => {}, "Project" => {}, "Institution" => {}, "Investigation" => {},
               "Study" => {}, "Experiment" => {}, "Specimen" =>{}, "Sample" => {}, "DataFile" => {}, "Model" => {}, "Protocol" => {}, "Publication" => {},"Presentation" => {}, "Event" => {}}

    related.each_key do |key|
      related[key][:items] = []
      related[key][:hidden_count] = 0
      related[key][:extra_count] = 0
    end

    case name
      when "DataFile"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["Study"][:items] = resource.studies
        related["Experiment"][:items] = resource.experiments
        related["Publication"][:items] = resource.related_publications
        related["Event"][:items] = resource.events
      when "Protocol"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["Study"][:items] = resource.studies
        related["Experiment"][:items] = resource.experiments
        related["Publication"][:items] = resource.related_publications
        related["Sample"][:items] = resource.specimens.collect{|spec| spec.samples}.flatten.uniq
      when "Model"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["Study"][:items] = resource.studies
        related["Experiment"][:items] = resource.experiments
        related["Publication"][:items] = resource.related_publications
      when "Experiment"
        related["Project"][:items] = resource.projects
        related["Investigation"][:items] = [resource.investigation]
        related["Study"][:items] = [resource.study]
        related["DataFile"][:items] = resource.data_file_masters
        related["Model"][:items] = resource.model_masters if resource.is_modelling? #MODELLING ASSAY
        related["Protocol"][:items] = resource.protocol_masters
        related["Publication"][:items] = resource.related_publications
      when "Investigation"
        related["Project"][:items] = resource.projects
        related["Study"][:items] = resource.studies
        related["Experiment"][:items] = resource.experiments
        related["DataFile"][:items] = resource.data_file_masters
        related["Model"][:items] = resource.model_masters
        related["Protocol"][:items] = resource.protocol_masters
      when "Study"
        related["Project"][:items] = resource.projects
        related["Investigation"][:items] = [resource.investigation]
        related["Experiment"][:items] = resource.experiments
        related["DataFile"][:items] = resource.data_file_masters
        related["Protocol"][:items] = resource.protocol_masters
        related["Model"][:items] = resource.model_masters
      when "Organism"
        related["Project"][:items] = resource.projects
        related["Experiment"][:items] = resource.experiments
        related["Model"][:items] = resource.models
        related["Sample"][:items] = resource.specimens.collect{|spec| spec.samples}.flatten
      when "Person"
        related["Project"][:items] = resource.projects
        related["Institution"][:items] = resource.institutions
        related["Study"][:items] = resource.studies
        user = resource.user
        if user
          related["DataFile"][:items] = user.data_files
          related["Model"][:items] = user.models
          related["Protocol"][:items] = user.protocols
          related["Presentation"][:items] = user.presentations
          related["Event"][:items] = user.events
        end
        related["DataFile"][:items] = related["DataFile"][:items] | resource.created_data_files
        related["Model"][:items] = related["Model"][:items] | resource.created_models
        related["Protocol"][:items] = related["Protocol"][:items] | resource.created_protocols
        related["Publication"][:items] = related["Publication"][:items] | resource.created_publications
        related["Presentation"][:items] = related["Presentation"][:items] | resource.created_presentations
        related["Experiment"][:items] = resource.experiments
      when "Institution"
        related["Project"][:items] = resource.projects
        related["Person"][:items] = resource.people
      when "Project"
        related["Event"][:items] = resource.events
        related["Person"][:items] = resource.people
        related["Institution"][:items] = resource.institutions
        related["Investigation"][:items] = resource.investigations
        related["Study"][:items] = resource.studies
        related["Experiment"][:items] = resource.experiments
        related["DataFile"][:items] = resource.data_files
        related["Model"][:items] = resource.models
        related["Protocol"][:items] = resource.protocols
        related["Publication"][:items] = resource.publications
        related["Presentation"][:items]= resource.presentations
      when "Publication"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["DataFile"][:items] = resource.related_data_files
        related["Model"][:items] = resource.related_models
        related["Experiment"][:items] = resource.related_experiments
        related["Event"][:items] = resource.events
      when "Presentation"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["Publication"][:items] = resource.related_publications
        related["Event"][:items] = resource.events

      when "Event"
        {#"Person" => [resource.contributor.try :person], #assumes contributor is a person. Currently that should always be the case, but that could change.
         "Project" => resource.projects,
         "DataFile" => resource.data_files,
         "Publication" => resource.publications,
        "Presentation"=> resource.presentations }.each do |k, v|
          related[k][:items] = v unless v.nil?
        end
      when "Specimen"
        related["Institution"][:items] = [resource.institution]
        related["Person"][:items] = resource.creators
        related["Project"][:items] = resource.projects
        related["Sample"][:items] = resource.samples
        related["Protocol"][:items] = resource.protocols
      when "Sample"
        related["Institution"][:items] = [resource.institution]
        related["Project"][:items] = resource.projects
        related["Experiment"][:items] = resource.experiments
        related["Protocol"][:items] = resource.specimen.protocols | resource.protocols
      else
    end
    
    #Authorize
    related.each_value do |resource_hash|
      resource_hash[:items].compact!
      unless resource_hash[:items].empty?
        total_count = resource_hash[:items].size
        resource_hash[:items] = resource_hash[:items].select &:can_view?
        resource_hash[:hidden_count] = total_count - resource_hash[:items].size
      end
    end    
    
    #Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      if limit && related[key][:items].size > limit && ["Project", "Investigation", "Study", "Experiment", "Person", "Specimen", "Sample"].include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]
      end
    end

    return related
  end

  def filter_url(resource_type, context_resource)
    #For example, if context_resource is a project with an id of 1, filter text is "(:filter => {:project => 1}, :page=>'all')"
    filter_text = "(:filter => {:#{context_resource.class.name.downcase} => #{context_resource.id}},:page=>'all')"
    eval("#{resource_type.underscore.pluralize}_path" + filter_text)
  end

  #provides a list of assets, according to the class, that are authorized acording the 'action' which defaults to view
  #if projects is provided, only authorizes the assets for that project
  def authorised_assets asset_class,projects=nil, action="view"
    asset_class.all_authorized_for action, User.current_user, projects
  end

  def asset_buttons asset,version=nil,delete_confirm_message=nil
     human_name = text_for_resource asset
     delete_confirm_message ||= "This deletes the #{human_name} and all metadata. Are you sure?"

     render :partial=>"assets/asset_buttons",:locals=>{:asset=>asset,:version=>version,:human_name=>human_name,:delete_confirm_message=>delete_confirm_message}
  end

  def asset_version_links asset_versions
    asset_version_links = []
    asset_versions.select(&:can_view?).each do |asset_version|
      asset_name = asset_version.class.name.split('::').first.underscore
      asset_version_links << link_to(asset_version.title, eval("#{asset_name}_path(#{asset_version.send("#{asset_name}_id")})") + "?version=#{asset_version.version}", {:target => '_blank'})
    end
    asset_version_links
  end

end
