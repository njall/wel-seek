# Methods added to this helper will be available to all templates in the application.
require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'helpers', 'application_helper')
module ApplicationHelper  
  include SavageBeast::ApplicationHelper
  include FancyMultiselectHelper


  def date_as_string date,show_time_of_day=false
    if date.blank?
      str="<span class='none_text'>No date defined</span>"
    else
      str = date.localtime.strftime("#{date.day.ordinalize} %B %Y")
      str = date.localtime.strftime("#{str} @ %H:%M:%S") if show_time_of_day
    end
    str
  end

  def version_text
    "(v.#{APP_VERSION.to_s})"
  end

  def authorized_list all_items, attribute, sort=true, max_length=75, count_hidden_items=false
    items = all_items.select &:can_view?
    title_only_items = (all_items - items).select &:title_is_public?
    html  = "<b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    if items.empty? and title_only_items.empty?
      html << "<span class='none_text'>No #{attribute}</span>"
    else
      original_size     = all_items.size
      hidden_item_count = original_size - (items.size + title_only_items.size)

      items = items.sort_by { |i| get_object_title(i) } if sort
      title_only_items = title_only_items.sort_by{|i| get_object_title(i)} if sort

      list = items.collect {|i| link_to h(truncate(i.title, :length=>max_length)), show_resource_path(i), :title=>get_object_title(i)}
      list = list + title_only_items.collect {|i| h(truncate(i.title, :length => max_length))}
      html << list.join(', ')

      if count_hidden_items && hidden_item_count>0
        html << "<span class=\"none_text\">#{items.size > 0 ? " and " : ""}#{hidden_item_count} hidden #{hidden_item_count > 1 ? "items" :"item"}</span>"
      end
    end
    html
  end

  def tabbar
    Seek::Config.is_virtualliver ? render(:partial=>"layouts/tabnav_dropdown") : render(:partial=>"layouts/tabnav")
  end

  #joins the list with seperator and the last item with an 'and'
  def join_with_and list, seperator=", "
    return list.first if list.count==1
    result = ""
    list.each do |item|
      result << item
      unless item==list.last
        if item==list[-2]
          result << " and "
        else
          result << seperator
        end
      end
    end
    result
  end

  def tab_definition(options={})
    options[:gap_before] ||= false
    options[:title] ||= options[:controllers].first.capitalize
    options[:path] ||= eval "#{options[:controllers].first}_path"

    attributes = (options[:controllers].include?(controller.controller_name.to_s) ? ' id="selected_tabnav"' : '')
    attributes += " class='tab_gap_before'" if options[:gap_before]

    link=link_to options[:title], options[:path]
    "<li #{attributes}>#{link}</li>"
  end

  #returns true if the current user is associated with a profile that is marked as a PAL
  def current_user_is_pal?
    current_user && current_user.person && current_user.person.is_pal?
  end

  #Classifies each result item into a hash with the class name as the key.
  #
  #This is to enable the resources to be displayed in the asset tabbed listing by class
  def classify_for_tabs result_collection
    results={}

    result_collection.each do |res|
      results[res.class.name] = {:items => [], :hidden_count => 0} unless results[res.class.name]
      results[res.class.name][:items] << res
    end

    return results
  end

  def new_creatable_javascript
    script="<script type='text/javascript'>\n"
    script << "function newAsset() {\n"
    script << "selected_model=$('new_resource_type').value;\n"
    Seek::Util.user_creatable_types.each do |c|
      name=c.name.underscore
      path = eval "new_#{name}_path"
      if c==Seek::Util.user_creatable_types.first
        script << "if "
      else
        script << "else if "
      end
      script << "(selected_model == '#{name}') {\n location.href = '#{path}';\n }\n"

    end
    script << "}\n"
    script << "</script>"
  end

  #selection of assets for new asset gadget
  def new_creatable_selection
    select_tag :new_resource_type, options_for_select(Seek::Util.user_creatable_types.collect{|c| [(c.name.underscore.humanize == "Protocol" ? "Protocol" : c.name.underscore.humanize),c.name.underscore] })
  end
  
  def is_nil_or_empty? thing
    thing.nil? or thing.empty?
  end
  
  def empty_list_li_text list
    return "<li><div class='none_text'> None specified</div></li>" if is_nil_or_empty?(list)
  end  

  def model_title_or_not_specified model
    text=model.nil? ? nil : model.title
    text_or_not_specified text,:capitalize=>true    
  end
  
  def text_or_not_specified text, options = {}
    text=text.to_s if text.kind_of?(Numeric)
    if text.nil? or text.chomp.empty?
      not_specified_text=options[:none_text] || "Not specified"
      not_specified_text="No description set" if options[:description]==true
      res = "<span class='none_text'>#{not_specified_text}</span>"
    else      
      text.capitalize! if options[:capitalize]            
      res=text
      res = white_list(res)
      res = truncate_without_splitting_words(res, options[:length])  if options[:length]
      res = auto_link(res, :all, :rel => 'nofollow') if options[:auto_link]==true  
      res = simple_format(res) if options[:description]==true || options[:address]==true
      
      res=mail_to(res) if options[:email]==true
      res=link_to(res,res,:popup=>true) if options[:external_link]==true
      res=res+"&nbsp;"+flag_icon(text) if options[:flag]==true
      res = "&nbsp;" + flag_icon(text) + link_to(res,country_path(res)) if options[:link_as_country]==true 
    end
    return res
  end

  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
      
  # text in "caption" will be used to display the item next to the image_tag_for_key;
  # if "caption" is nil, item.name will be used by default
  def list_item_with_icon(icon_type, item, caption, truncate_to, custom_tooltip=nil, size=nil)
    list_item = "<li>"
    if icon_type.downcase == "flag"
      list_item += flag_icon(item.country)
    elsif icon_type == "data_file" || icon_type == "protocol"
      list_item += file_type_icon(item)
    else
      list_item += image_tag_for_key(icon_type.downcase, nil, icon_type.camelize, nil, "", false, size)
    end
    item_caption = " " + h(caption.blank? ? item.name : caption)
    list_item += link_to truncate(item_caption, :length=>truncate_to), url_for(item), :title => tooltip_title_attrib(custom_tooltip.blank? ? item_caption : custom_tooltip)
    list_item += "</li>"
    
    return list_item
  end
  
  
  def contributor(contributor, avatar=false, size=100, you_text=false)
    return jerm_harvester_name unless contributor
    
    if contributor.class.name == "User"
      # this string will output " (you) " for current user next to the display name, when invoked with 'you_text == true'
      you_string = (you_text && logged_in? && user.id == current_user.id) ? "<small style='vertical-align: middle; color: #666666; margin-left: 0.5em;'>(you)</small>" : ""
      contributor_person = contributor.person
      contributor_name = h(contributor_person.name)
      contributor_url = person_path(contributor_person.id)
      contributor_name_link = link_to(contributor_name, contributor_url)
      
      if avatar
        result = avatar(contributor_person, size, false, contributor_url, contributor_name, false)
        result += "<p style='margin: 0; text-align: center;'>#{contributor_name_link}#{you_string}</p>"
        return result
      else
        return (contributor_name_link + you_string)
      end
      # other types might be supported
      # elsif contributortype.to_s == "Network"
      #network = Network.find(:first, :select => "id, title", :conditions => ["id = ?", contributorid])
      #return nil unless network
      #
      #return title(network)
    else
      return nil
    end
  end
  
  # this helper is to be extended to include many more types of objects that can belong to the
  # user - for example, Protocols and others
  def mine?(thing)
    return false if thing.nil?
    return false unless logged_in?
    
    c_id = current_user.id.to_i
    
    case thing.class.name
    when "Person"
      return (current_user.person.id == thing.id)
    else
      return false
    end
  end
  
  def fast_auto_complete_field(field_id, options={})
    div_id = "#{field_id}_auto_complete"
    url = options.delete(:url) or raise "url required"
    options = options.merge(:tokens => ',', :frequency => 0.01 )
    script = javascript_tag <<-end
    new Ajax.Request('#{url}', {
      method: 'get',
      onSuccess: function(transport) {
        new Autocompleter.Local('#{field_id}', '#{div_id}', eval(transport.responseText), #{options.to_json});
      }
    });
    end
    content_tag 'div', script, :class => 'auto_complete', :id => div_id
  end

  def link_to_draggable(link_name, url, link_options = {}, drag_options = {})
    if !link_options[:id]
      return ":id mandatory"
    end
    
    can_click_var = "can_click_for_#{link_options[:id]}"
    html = javascript_tag("var #{can_click_var} = true;");
    html << link_to(
      link_name,
      url,
      :id => link_options[:id],
      :class => link_options[:class] || "",
      :title => link_options[:title] || "",
      :onclick => "if (!#{can_click_var}) {#{can_click_var}=true;return(false);} else {return true;}",
      :onMouseUp => "setTimeout('#{can_click_var} = true;', 200);")
    html << draggable_element(link_options[:id],
      :revert => drag_options[:revert] || true,
      :ghosting => drag_options[:ghosting] || false,
      :change => "function(element){#{can_click_var} = false;}")
    return html
  end

  def page_title controller_name, action_name
    name=PAGE_TITLES[controller_name]
    name ||=""
    name += " (Development)" if RAILS_ENV=="development"
    return "#{Seek::Config.application_title} "+name
  end

  # http://www.igvita.com/blog/2006/09/10/faster-pagination-in-rails/
  def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size]

    current_page = pagingEnum.page
    html = ''

    #Calculate the window start and end pages
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

    # Print start page if anchors are enabled
    html << yield(1) if always_show_anchors and not first == 1

    # Print window pages
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end

    # Print end page if anchors are enabled
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end

  def favourite_group_popup_link_action_new resource_type=nil
    return link_to_remote_redbox("Create new favourite group",
      { :url => new_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}'" },
      { #:style => options[:style],
        :id => "create_new_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" }#,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def favourite_group_popup_link_action_edit resource_type=nil
    return link_to_remote_redbox("Edit selected favourite group",
      { :url => edit_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}' + '&id=' + selectedFavouriteGroup()" },
      { #:style => options[:style],
        :id => "edit_existing_f_group_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  def workgroup_member_review_popup_link resource_type=nil
    return link_to_remote_redbox("<b>Review members, set individual<br/>permissions and add afterwards</b>", 
      { :url => review_work_group_url("type", "id", "access_type"),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'resource_type=' + '#{resource_type}'" },
      { #:style => options[:style],
        :id => "review_work_group_redbox" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  
  # the parameter must be the *standard* name of the whitelist or blacklist (depending on the link that needs to be produced)
  # (standard names are defined in FavouriteGroup model)
  def whitelist_blacklist_edit_popup_link(f_group_name)
    return link_to_remote_redbox("edit", 
      { :url => edit_favourite_group_url,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      { #:style => options[:style],
        :id => "#{f_group_name}_edit_redbox",
        :onclick => "javascript: currentFavouriteGroupSettings = {};" } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end

  def preview_permission_popup_link resource
    resource_name = resource.class.name.underscore
    resource_id = resource.id
    url = url_for(:controller => 'policies', :action => 'preview_permissions')
    is_new_file = resource.new_record?
    contributor_id = resource.contributing_user.try(:id)
    return link_to_remote_redbox("preview permission",
      { :url => url ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'sharing_scope=' + selectedSharingScope() + '&access_type=' + selectedAccessType(selectedSharingScope())
        + '&project_ids=' + getProjectIds('#{resource_name}') + '&project_access_type=' + $F('sharing_your_proj_access_type')
        + '&contributor_types=' + $F('sharing_permissions_contributor_types') + '&contributor_values=' + $F('sharing_permissions_values')
        + '&creators=' + getCreators() + '&contributor_id=' + '#{contributor_id}' + '&resource_name=' + '#{resource_name}' + '&resource_id=' + '#{resource_id}' + '&is_new_file=' + '#{is_new_file}'"},
      { :id => 'preview_permission',
        :style => 'display:none'
      } #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
  #Return whether or not to hide contact details from this user
  #Current decided by Seek::Config.hide_details_enabled in config.rb
  #Defaults to false
  def hide_contact_details?
    #hide for non-login and non-project-member
    if !logged_in? or !current_user.person.member?
      return true
    else
      Seek::Config.hide_details_enabled
    end
  end

  # Finn's truncate method. Doesn't split up words, tries to get as close to length as possible
  def truncate_without_splitting_words(text, length=50)
    truncated_result = ""
    remaining_length = length
    stop = false
    truncated = false
    #lines
    text.split("\n").each do |l|
      #words
      l.split(" ").each do |w|
        #If we're going to go over the length, and we've not already
        if (remaining_length - w.length) <= 0 && !stop
          truncated = true
          stop = true
          #Decide if adding or leaving out the last word puts us closer to the desired length
          if (remaining_length-w.length).abs < remaining_length.abs
            truncated_result += (w + " ")
          end
        elsif !stop
          truncated_result += (w + " ")
          remaining_length -= (w.length + 1)
        end
      end
      truncated_result += "\n"
    end    
    #Need some kind of whitespace before elipses or auto-link breaks
    truncated_result.strip + (truncated ? "\n..." : "")
  end    
  
  def get_object_title(item)
    title = ""
    
    if ["Person", "Institution", "Project"].include? item.class.name
      title = h(item.name)          
    else
      title = h(item.title)
    end
    return title
  end

  def can_manage_announcements?
    return admin_logged_in?
  end

  def show_or_hide_block visible=true
    "display:" + (visible ? 'block' : 'none')
  end

  def toggle_appear_javascript block_id
    "Effect.toggle('#{block_id}','slide',{duration:0.5})"
  end

  def count_actions(object, actions=nil)
    count = 0
    if actions.nil?
      count = ActivityLog.count(:conditions => {:activity_loggable_type => object.class.name, :activity_loggable_id => object.id})
    else
      count = ActivityLog.count(:conditions => {:action => actions, :activity_loggable_type => object.class.name, :activity_loggable_id => object.id})
    end
    count
  end

  def set_parameters_for_sharing_form object=nil
    object ||= eval "@#{controller_name.singularize}"
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if object
      if object.instance_of? Project
        if object.default_policy
          policy = object.default_policy
          policy_type ="project"
        else
          policy = Policy.default
          policy_type = "system"
        end
      elsif (policy = object.policy)
        # object exists and has a policy associated with it - normal case
        policy_type = "asset"
      end
    end

    unless policy
      policy = Policy.default
      policy_type = "system"
    end

    # set the parameters
    # ..from policy
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    @access_mode = policy.access_type
    @use_custom_sharing = !policy.permissions.empty?
    @use_whitelist = (policy.use_whitelist == true || policy.use_whitelist == 1)
    @use_blacklist = (policy.use_blacklist == true || policy.use_blacklist == 1)

    # ..other
    @resource_type = text_for_resource object
    @favourite_groups = current_user.favourite_groups
    @resource = object

    @all_people_as_json = Person.get_all_as_json

    @enable_black_white_listing = @resource.nil? || (@resource.respond_to?(:contributor) and !@resource.contributor.nil?)
  end

  def folding_box id, title, options = nil
    render :partial => 'assets/folding_box', :locals =>
        {:fold_id => id,
         :fold_title => title,
         :contents => options[:contents],
         :hidden => options[:hidden]}
  end

  def require_js file
    #TODO: Needs testing, not sure what the 'lifecycle' for instance variables in a helper is.
    #Needs to last as long as the page is being rendered and no longer. The intent is to include the js only if it hasn't already been included.
    @required_js ||= []
    unless @required_js.include? file
      @required_js << file
      javascript_include_tag file
    end
  end

  def display_people_list people
    html = "<ul class='people_list'>"
    people.each do |person|
       html<< "<li><a href='#{person_path(person[0])}' target='_blank'>#{person[1]}</a></li>"
    end
    html << '</ul>'
  end


  private  
  PAGE_TITLES={"home"=>"Home", "projects"=>"Projects","institutions"=>"Institutions", "people"=>"People", "sessions"=>"Login","users"=>"Signup","search"=>"Search","experiments"=>"Experiments","protocols"=>"Protocols","models"=>"Models","data_files"=>"Data","publications"=>"Publications","investigations"=>"Investigations","studies"=>"Studies","specimens"=>"Specimens","samples"=>"Samples","presentations"=>"Presentations"}
end

class ApplicationFormBuilder< ActionView::Helpers::FormBuilder
  def fancy_multiselect association, options = {}
    @template.fancy_multiselect object, association, options
  end
end

ActionView::Base.default_form_builder = ApplicationFormBuilder
