# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper
  
  def info_icon_with_tooltip(info_text, delay=200)
    return image("info",
      :title => tooltip_title_attrib(info_text, delay),
      :style => "vertical-align:middle;")
  end

  #mirrors image_tag but uses a key instead of a source
  def simple_image_tag_for_key key, options={}
    return nil unless (filename = icon_filename_for_key(key.downcase))
    image_tag filename,options
  end

  def image_tag_for_key(key, url=nil, alt=nil, url_options={}, label=key.humanize, remote=false, size=nil)

    if (label == 'Destroy')
      label = 'Delete';
    end
    
    return nil unless (filename = icon_filename_for_key(key.downcase))

    image_options = alt ? { :alt => alt } : { :alt => key.humanize }
    image_options[:size] = "#{size}x#{size}" unless size.blank?
    img_tag = image_tag(filename, image_options)

    inner = img_tag;
    inner = "#{img_tag} #{label}" unless label.blank?
    
    if (url)
      if (remote==:function)
        inner = link_to_function inner, url, url_options
      elsif (remote)
        inner = link_to_remote(inner, url, url_options);
      else
        inner = link_to(inner, url, url_options)
      end
    end
    
    return '<span class="icon">' + inner + '</span>';
  end

  def resource_avatar resource,html_options={}

    if resource.avatar_key
          image_tag(icon_filename_for_key(resource.avatar_key), html_options)
    elsif resource.use_mime_type_for_avatar?
          image_tag(file_type_icon_url(resource), html_options)
    end
  end
  
  def icon_filename_for_key(key)
    case (key.to_s)
      when "refresh"
      "famfamfam_silk/arrow_refresh_small.png"
      when "arrow_up"
      "famfamfam_silk/arrow_up.png"
      when "arrow_down"
      "famfamfam_silk/arrow_down.png"
      when "arrow_right", "next"
      "famfamfam_silk/arrow_right.png"
      when "arrow_left", "back"
      "famfamfam_silk/arrow_left.png"
      when "bioportal_logo"
      "logos/bioportal_logo.png"
      when "new","add"
      "famfamfam_silk/add.png"
      when "multi_add"
      "famfamfam_silk/table_add.png"
      when "download"
      "redmond_studio/arrow-down_16.png"
      when "show"
      "famfamfam_silk/zoom.png"
      when "edit"
      "famfamfam_silk/page_white_edit.png"
      when "edit-off"
      "stop_edit.png"
      when "manage"
      "famfamfam_silk/wrench.png"
      when "destroy"
      "famfamfam_silk/cross.png"
      when "tag"
      "famfamfam_silk/tag_blue.png"
      when "favourite"
      "famfamfam_silk/star.png"
      when "comment"
      "famfamfam_silk/comment.png"
      when "comments"
      "famfamfam_silk/comments.png"
      when "info"
      "famfamfam_silk/information.png"
      when "help"
      "famfamfam_silk/help.png"
      when "confirm"
      "famfamfam_silk/accept.png"
      when "reject"
      "famfamfam_silk/cancel.png"
      when "user", "person"
      "famfamfam_silk/user.png"
      when "user-invite"
      "famfamfam_silk/user_add.png"
      when "avatar"
      "famfamfam_silk/picture.png"
      when "avatars"
      "famfamfam_silk/photos.png"
      when "save"
      "famfamfam_silk/save.png"
      when "message"
      "famfamfam_silk/email.png"
      when "message_read"
      "famfamfam_silk/email_open.png"
      when "reply"
      "famfamfam_silk/email_go.png"
      when "message_delete"
      "famfamfam_silk/email_delete.png"
      when "messages_outbox"
      "famfamfam_silk/email_go.png"
      when "file"
      "redmond_studio/documents_16.png"
      when "logout"
      "famfamfam_silk/door_out.png"
      when "login"
      "famfamfam_silk/door_in.png"
      when "picture"
      "famfamfam_silk/picture.png"
      when "pictures"
      "famfamfam_silk/photos.png"
      when "profile"
      "famfamfam_silk/user_suit.png"
      when "history"
      "famfamfam_silk/time.png"
      when "news"
      "famfamfam_silk/newspaper.png"
      when "view-all"
      "famfamfam_silk/table_go.png"
      when "announcement"
      "famfamfam_silk/transmit.png"
      when "denied"
      "famfamfam_silk/exclamation.png"
      when "institution"
      "famfamfam_silk/house.png"
      when "project"
      "famfamfam_silk/report.png"
      when "tick"
      "crystal_project/22x22/apps/clean.png"    
      when "lock"
      "famfamfam_silk/lock.png"
      when "open"
      "famfamfam_silk/lock_open.png"
      when "no_user"
      "famfamfam_silk/link_break.png"
      when "protocol"
      "famfamfam_silk/page.png"
      when "protocols"
      "famfamfam_silk/page_copy.png"
      when "model"
      "crystal_project/32x32/apps/kformula.png"
      when "models"
      "crystal_project/64x64/apps/kformula.png"
      when "data_file","data_files"
      "famfamfam_silk/database.png"
      when "study"
      "famfamfam_silk/page.png"
      when "test"
      "crystal_project/16x16/actions/run.png"
      when "execute"
      "famfamfam_silk/lightning.png"
      when "warning","warn"
      "crystal_project/22x22/apps/alert.png"
      when "skipped"
      "crystal_project/22x22/actions/undo.png"
      when "error"
      "famfamfam_silk/exclamation.png"
      when "feedback"
      "famfamfam_silk/email.png"
      when "spinner"
      "ajax-loader.gif"
      when "large-spinner"
      "ajax-loader-large.gif"
      when "current"
      "famfamfam_silk/bullet_green.png"
      when "collapse"
      "folds/fold.png"
      when "expand"
      "folds/unfold.png"
      when "pal"
      "famfamfam_silk/rosette.png"
      when "admin"
      "famfamfam_silk/shield.png"
      when "pdf_file"
      "file_icons/small/pdf.png"
      when "xls_file"
      "file_icons/small/xls.png"
      when "doc_file"
      "file_icons/small/doc.png"
      when "misc_file"
      "file_icons/small/genericBlue.png"
      when "ppt_file"
      "file_icons/small/ppt.png"
      when "xml_file"
      "file_icons/small/xml.png"
      when "zip_file"
      "file_icons/small/zip.png"
      when "jpg_file"
      "file_icons/small/jpg.png"
      when "gif_file"
      "file_icons/small/gif.png"
      when "png_file"
      "file_icons/small/png.png"
      when "txt_file"
      "file_icons/small/txt.png"
      when "investigation_avatar", 'investigation', 'investigations'
      "crystal_project/64x64/apps/mydocuments.png"
      when "study_avatar"
      "crystal_project/64x64/apps/package_editors.png"
      when "experiment_avatar","experiment_experimental_avatar", 'experiment'
      "misc_icons/flask3-64x64.png"
      when "experiment_modelling_avatar"
      "crystal_project/64x64/filesystems/desktop.png"
      when "model_avatar"
      "crystal_project/64x64/apps/kformula.png"
      when "person_avatar"
      "avatar.png"
      when "jerm_logo"
      "jerm_logo.png"
      when "project_avatar"
      "project_64x64.png"
      when "institution_avatar"
      "institution_64x64.png"
      when "organism_avatar"
      "misc_icons/cell3.png"
      when "publication_avatar", "publication", "publications"
     "crystal_project/64x64/mimetypes/wordprocessing.png"
      when "saved_search_avatar","saved_search"
      "crystal_project/32x32/actions/find.png"
      when "visit_pubmed"
      "famfamfam_silk/page_white_go.png"
      when "markup"
      "famfamfam_silk/page_white_text.png"
      when "atom_feed"
      "misc_icons/feed_icon.png"
      when "impersonate"
      "famfamfam_silk/group_go.png"
      when "world"
      "famfamfam_silk/world.png"
      when "file_large"
      "crystal_project/32x32/apps/klaptop.png"
      when "internet_large"
      "crystal_project/32x32/devices/Globe2.png"
      when "jws_builder"
        "misc_icons/jws_builder24x24.png"
      when "event_avatar"
        "crystal_project/32x32/apps/vcalendar.png"
      when "specimen_avatar"
        "misc_icons/green_virus-64x64.png"
      when "sample_avatar"
        "misc_icons/sampleBGXblue.png"
      when "specimen", "specimens"
        "misc_icons/green_virus-64x64.png"
      when "publish"
       "crystal_project/22x22/actions/up.png"
      when "spreadsheet"
      "famfamfam_silk/table.png"
      when "spreadsheet_annotation"
      "famfamfam_silk/tag_blue.png"
      when "spreadsheet_annotation_edit"
      "famfamfam_silk/tag_blue_edit.png"
      when "spreadsheet_annotation_add"
      "famfamfam_silk/tag_blue_add.png"
      when "spreadsheet_annotation_destroy"
      "famfamfam_silk/tag_blue_delete.png"
      when "spreadsheet_export"
      "famfamfam_silk/table_go.png"
      when 'unsubscribe'
        "famfamfam_silk/email_delete.png"
      when 'subscribe'
        "famfamfam_silk/email_add.png"
      when 'presentation_avatar','presentation','presentations'
        "misc_icons/1315482798_presentation-slides.png"
      when "graph"
        "famfamfam_silk/chart_line.png"
      when "project_manager"
        "famfamfam_silk/medal_gold_1.png"
      when "asset_manager"
        "famfamfam_silk/medal_bronze_3.png"
      when "gatekeeper"
        "famfamfam_silk/medal_silver_2.png"
      when "jws_shadow"
        "jws/shadow2.gif"
    else
      return nil
    end
  end
  
  def help_icon(text, delay=200, extra_style="")
    image_tag icon_filename_for_key("info"), :alt=>"help", :title=>tooltip_title_attrib(text,delay), :style => "vertical-align: middle;#{extra_style}"
  end
  
  def flag_icon(country, text=country, margin_right='0.3em')
    return '' if country.nil? or country.empty?
    
    code = ''
    
    if country.downcase == "great britain"
      code = "gb"
    elsif ["england", "wales", "scotland"].include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end
    
    unless code.nil? or code.empty?
      return image_tag("famfamfam_flags/#{code.downcase}.png",
        :title => "header=[] body=[<b>Location: </b>#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
        :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      return ''
    end
  end
  
  # A generic key to produce avatars for entities of all kinds.
  #
  # Parameters:
  # 1) object - the instance of the object which requires the avatar;
  # 2) size - size of the square are, where the avatar will reside (the aspect ratio of the picture is preserved by ImageMagick);
  # 3) return_image_tag_only - produces only the <img /> tag; the picture won't be linked to anywhere; no 'alt' / 'title' attributes;
  # 4) url - when the avatar is clicked, this is the url to redirect to; by default - the url of the "object";
  # 5) alt - text to show as 'alt' / 'tooltip'; by default "name" attribute of the "object"; when empty string - nothing is shown;
  # 6) "show_tooltip" - when set to true, text in "alt" get shown as tooltip; otherwise put in "alt" attribute
  def avatar(object, size=200, return_image_tag_only=false, url=nil, alt=nil, show_tooltip=true)
    alternative = ""
    title = get_object_title(object)
    if show_tooltip
      tooltip_text = (alt.nil? ? h(title) : alt)
    else
      alternative = (alt.nil? ? h(title) : alt)
    end
    
    case object.class.name.downcase
      when "person", "institution", "project"
      if object.avatar_selected?
        img = image_tag avatar_url(object, object.avatar_id, size), :alt=> alternative, :class => 'framed'
      else
        img = default_avatar(object.class.name, size, alternative)
      end
      when "datafile", "protocol"
      img = image_tag file_type_icon_url(object),
        :alt => alt,
        :class=> "avatar framed"
      when "model","investigation","study","publication"
      img = image "#{object.class.name.downcase}_avatar",
      {:alt => alt,
        :class=>"avatar framed"}
      when "experiment"
      type=object.is_modelling? ? "modelling" : "experimental"
      img = image "#{object.class.name.downcase}_#{type}_avatar",
      {:alt => alt,
        :class=>"avatar framed"}
    end
    
    # if the image of the avatar needs to be linked not to the url of the object, return only the image tag
    if return_image_tag_only
      return img
    else
      unless url
        url = eval("#{object.class.name.downcase}_url(#{object.id})")
      end
      
      return link_to(img, url, :title => tooltip_title_attrib(tooltip_text))
    end
  end
  
  def avatar_url(avatar_for_instance, avatar_id, size=nil)
    basic_url = eval("#{avatar_for_instance.class.name.downcase}_avatar_path(#{avatar_for_instance.id}, #{avatar_id})")
    
    if size
      basic_url += "?size=#{size}"
      basic_url += "x#{size}" if size.kind_of?(Numeric)
    end
    
    return basic_url
  end
  
  def default_avatar(object_class_name, size=200, alt="Anonymous", onclick_options="")
    avatar_filename=icon_filename_for_key("#{object_class_name.downcase}_avatar")
    
    image_tag avatar_filename,
      :alt => alt,
      :size => "#{size}x#{size}",
      :class => 'framed',
      :onclick => onclick_options
  end
  
  def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, :class => "icon"
  end

  def file_type_icon_key(item)
    mime_icon_key item.content_type
  end

  def file_type_icon_url(item)
    mime_icon_url item.content_type
  end
  
  def expand_image(margin_left="0.3em")
    image_tag icon_filename_for_key("expand"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand', :title=>tooltip_title_attrib("Expand for more details")
  end
  
  def collapse_image(margin_left="0.3em")
    image_tag icon_filename_for_key("collapse"), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse', :title=>tooltip_title_attrib("Collapse the details")
  end
  
  def image key,options={}
    image_tag(icon_filename_for_key(key),options)
  end
  
end
