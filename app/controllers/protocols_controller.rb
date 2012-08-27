class ProtocolsController < ApplicationController
  
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon  
  
  #before_filter :login_required
  before_filter :redirect_if_disabled
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_auth, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show,:download]


  include Seek::Publishing

  def redirect_if_disabled
    if !Seek::Config.protocols_enabled
      redirect_to :controller => 'home'
    end
  end


  def new_version
    if (handle_data nil)      
      comments=params[:revision_comment]
      
      @protocol.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object, :url=>@data_url)
      @protocol.content_type = params[:protocol][:content_type]
      @protocol.original_filename = params[:protocol][:original_filename]
      
      conditions = @protocol.experimental_conditions
      respond_to do |format|
        if @protocol.save_as_new_version(comments)
          #Duplicate experimental conditions
          conditions.each do |con|
            new_con = con.clone
            new_con.protocol_version = @protocol.version
            new_con.save
          end
          flash[:notice]="New version uploaded - now on version #{@protocol.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @protocol }
      end
    else
      flash[:error]=flash.now[:error] 
      redirect_to @protocol
    end
    
  end
  
  # GET /protocols/1
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @protocol.last_used_at
    
    # update timestamp in the current protocol record
    # (this will also trigger timestamp update in the corresponding Asset)
    if @protocol.instance_of?(Protocol)
      @protocol.last_used_at = Time.now
      @protocol.save_without_timestamping
    end  
    
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@protocol,params[:deep]=='true',@protocol)}
      format.dot { render :text=>to_dot(@protocol,params[:deep]=='true',@protocol)}
      format.png { render :text=>to_png(@protocol,params[:deep]=='true',@protocol)}
    end
  end
  
  # GET /protocols/1/download
  def download
    # update timestamp in the current protocol record
    # (this will also trigger timestamp update in the corresponding Asset)
    @protocol.last_used_at = Time.now
    @protocol.save_without_timestamping
    
    handle_download @display_protocol
  end
  
  # GET /protocols/new
  def new
    @protocol=Protocol.new
    respond_to do |format|
      if current_user.person.member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new protocols. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to protocols_path }
      end
    end
  end
  
  # GET /protocols/1/edit
  def edit
    
  end
  
  # POST /protocols
  def create    

    if handle_data            
      @protocol = Protocol.new(params[:protocol])
      @protocol.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object,:url=>@data_url)

      @protocol.policy.set_attributes_with_sharing params[:sharing], @protocol.projects

      update_annotations @protocol
      experiment_ids = params[:experiment_ids] || []
      respond_to do |format|
        if @protocol.save
          # update attributions
          Relationship.create_or_update_attributions(@protocol, params[:attributions])
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@protocol, params[:creators])
          
          flash[:notice] = 'protocol was successfully uploaded and saved.'
          format.html { redirect_to protocol_path(@protocol) }
          Experiment.find(experiment_ids).each do |experiment|
            if experiment.can_edit?
              experiment.relate(@protocol)
            end
          end
          deliver_request_publish_approval params[:sharing], @protocol
        else
          format.html { 
            render :action => "new" 
          }
        end
      end
    end
  end
  
  
  # PUT /protocols/1
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:protocol]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:protocol].delete(column_name)
      end
      
      # update 'last_used_at' timestamp on the protocol
      params[:protocol][:last_used_at] = Time.now
    end

    update_annotations @protocol
    experiment_ids = params[:experiment_ids] || []

    @protocol.attributes = params[:protocol]

    if params[:sharing]
      @protocol.policy_or_default
      @protocol.policy.set_attributes_with_sharing params[:sharing], @protocol.projects
    end

    respond_to do |format|
      if @protocol.save
        # update attributions
        Relationship.create_or_update_attributions(@protocol, params[:attributions])
        
        #update authors
        AssetsCreator.add_or_update_creator_list(@protocol, params[:creators])
        
        flash[:notice] = 'protocol metadata was successfully updated.'
        format.html { redirect_to protocol_path(@protocol) }
        # Update new experiment_asset
        Experiment.find(experiment_ids).each do |experiment|
          if experiment.can_edit?
            experiment.relate(@protocol)
          end
        end

        #Destroy ExperimentAssets that aren't needed
        experiment_assets = @protocol.experiment_assets
        experiment_assets.each do |experiment_asset|
          if experiment_asset.experiment.can_edit? and !experiment_ids.include?(experiment_asset.experiment_id.to_s)
            ExperimentAsset.destroy(experiment_asset.id)
          end
        end
        deliver_request_publish_approval params[:sharing], @protocol
      else
        format.html { 
          render :action => "edit" 
        }
      end
    end
  end
  
  # DELETE /protocols/1
  def destroy
    @protocol.destroy
    
    respond_to do |format|
      format.html { redirect_to(protocols_path) }
    end
  end

  
  def preview
    
    element=params[:element]
    protocol=Protocol.find_by_id(params[:id])
    
    render :update do |page|
      if protocol.try :can_view?
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>protocol}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end
  
  def request_resource
    resource = Protocol.find(params[:id])
    details = params[:details]
    
    Mailer.deliver_request_resource(current_user,resource,details,base_host)
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end

end
