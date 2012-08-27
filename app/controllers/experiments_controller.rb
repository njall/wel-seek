class ExperimentsController < ApplicationController

  include DotGenerator
  include IndexPager
  include Seek::AnnotationCommon

  before_filter :redirect_if_disabled
  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_auth, :only=>[:edit, :update, :destroy, :show]

  include Seek::Publishing


  def redirect_if_disabled
    if !Seek::Config.experiments_enabled
      redirect_to :controller => 'home'
    end
  end


   def new_object_based_on_existing_one
    @existing_experiment =  Experiment.find(params[:id])
    @experiment = @existing_experiment.clone_with_associations
    params[:data_file_ids]=@existing_experiment.data_file_masters.collect{|d|"#{d.id},None"}
    params[:related_publication_ids]= @existing_experiment.related_publications.collect{|p| "#{p.id},None"}

    unless @experiment.study.can_edit?
      @experiment.study = nil
      flash.now[:notice] = "The study of the existing experiment cannot be viewed, please specify your own study! <br/>"
    end

    @existing_experiment.data_file_masters.each do |d|
      if !d.can_view?
       flash.now[:notice] << "Some or all data files of the existing experiment cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_experiment.protocol_masters.each do |s|
       if !s.can_view?
       flash.now[:notice] << "Some or all protocols of the existing experiment cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_experiment.model_masters.each do |m|
       if !m.can_view?
       flash.now[:notice] << "Some or all models of the existing experiment cannot be viewed, you may specify your own! <br/>"
        break
      end
    end

    render :action=>"new"
   end

  def new
    @experiment=Experiment.new
    @experiment.create_from_asset = params[:create_from_asset]
    study = Study.find(params[:study_id]) if params[:study_id]
    @experiment.study = study if params[:study_id] if study.try :can_edit?
    @experiment_class=params[:class]
    @experiment.experiment_class=ExperimentClass.for_type(@experiment_class) unless @experiment_class.nil?

    investigations = Investigation.all.select &:can_view?
    studies=[]
    investigations.each do |i|
      studies << i.studies.select(&:can_view?)
    end
    respond_to do |format|
      if investigations.blank?
         flash.now[:notice] = "No study and investigation available, you have to create a new investigation first before creating your study and experiment!"
      else
        if studies.flatten.blank?
          flash.now[:notice] = "No study available, you have to create a new study before creating your experiment!"
        end
      end

      format.html
      format.xml
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def create
    @experiment        = Experiment.new(params[:experiment])

    organisms     = params[:experiment_organism_ids] || []
    protocol_ids       = params[:experiment_protocol_ids] || []
    data_file_ids = params[:data_file_ids] || []
    model_ids     = params[:experiment_model_ids] || []


     organisms.each do |text|
      o_id, strain, culture_growth_type_text=text.split(",")
      culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
      @experiment.associate_organism(o_id, strain, culture_growth)
    end


    update_annotations @experiment

    @experiment.owner=current_user.person

    @experiment.policy.set_attributes_with_sharing params[:sharing], @experiment.projects


      if @experiment.save
        data_file_ids.each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          @experiment.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        model_ids.each do |a_id|
          m = Model.find(a_id)
          @experiment.relate(m) if m.can_view?
        end
        protocol_ids.each do |a_id|
          s = Protocol.find(a_id)
          @experiment.relate(s) if s.can_view?
        end

        # update related publications
        Relationship.create_or_update_attributions(@experiment, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        #required to trigger the after_save callback after the assets have been associated
        @experiment.save

        deliver_request_publish_approval params[:sharing], @experiment

        if @experiment.create_from_asset =="true"
          render :action=>:update_experiments_list
        else
          respond_to do |format|
          flash[:notice] = 'Experiment was successfully created.'
          format.html { redirect_to(@experiment) }
          format.xml { render :xml => @experiment, :status => :created, :location => @experiment }
          end
        end
      else
        respond_to do |format|
        format.html { render :action => "new" }
        format.xml { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    #FIXME: would be better to resolve the differences, rather than keep clearing and reading the assets and organisms
    #DOES resolve differences for assets now
    organisms             = params[:experiment_organism_ids]||[]

    organisms             = params[:experiment_organism_ids] || []
    protocol_ids               = params[:experiment_protocol_ids] || []
    data_file_ids         = params[:data_file_ids] || []
    model_ids             = params[:experiment_model_ids] || []
    publication_params    = params[:related_publication_ids].nil?? [] : params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first]}

    @experiment.experiment_organisms = []
    organisms.each do |text|
          o_id, strain, culture_growth_type_text=text.split(",")
          culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
          @experiment.associate_organism(o_id, strain, culture_growth)
        end

    update_annotations @experiment

    experiment_assets_to_keep = [] #Store all the asset associations that we are keeping in this
    @experiment.attributes = params[:experiment]
    if params[:sharing]
      @experiment.policy_or_default
      @experiment.policy.set_attributes_with_sharing params[:sharing], @experiment.projects
    end

    respond_to do |format|
      if @experiment.save
        data_file_ids.each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          experiment_assets_to_keep << @experiment.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        model_ids.each do |a_id|
          m = Model.find(a_id)
          experiment_assets_to_keep << @experiment.relate(m) if m.can_view?
        end
        protocol_ids.each do |a_id|
          s = Protocol.find(a_id)
          experiment_assets_to_keep << @experiment.relate(s) if s.can_view?
        end
        #Destroy ExperimentAssets that aren't needed
        (@experiment.experiment_assets - experiment_assets_to_keep.compact).each { |a| a.destroy }

        # update related publications

        Relationship.create_or_update_attributions(@experiment,publication_params, Relationship::RELATED_TO_PUBLICATION)

        #FIXME: required to update timestamp. :touch=>true on ExperimentAsset association breaks acts_as_trashable
        @experiment.updated_at=Time.now
        @experiment.save!
        deliver_request_publish_approval params[:sharing], @experiment

        flash[:notice] = 'Experiment was successfully updated.'
        format.html { redirect_to(@experiment) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@experiment.study, params[:deep]=='true', @experiment) }
      format.dot { render :text=>to_dot(@experiment.study, params[:deep]=='true', @experiment) }
      format.png { render :text=>to_png(@experiment.study, params[:deep]=='true', @experiment) }
    end
  end

  def destroy

    respond_to do |format|
      if @experiment.can_delete?(current_user) && @experiment.destroy
        format.html { redirect_to(experiments_url) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the experiment" if !@experiment.study.nil?
        format.html { render :action=>"show" }
        format.xml { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_types
    render :update do |page|
      page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
    end
  end

  def preview
    element=params[:element]
    experiment  =Experiment.find_by_id(params[:id])

    render :update do |page|
      if experiment.try :can_view?
        page.replace_html element, :partial=> "experiments/associate_resource_list_item", :locals=>{:resource=>experiment}
      else
        page.replace_html element, :text=>"Nothing is selected to preview."
      end
    end
  end
end
