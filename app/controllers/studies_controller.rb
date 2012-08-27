class StudiesController < ApplicationController

  include DotGenerator
  include IndexPager

  before_filter :redirect_if_disabled
  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_auth, :only=>[:edit, :update, :destroy, :show]

  before_filter :check_experiments_are_not_already_associated_with_another_study,:only=>[:create,:update]

  include Seek::Publishing



  def redirect_if_disabled
    if !Seek::Config.studies_enabled
      redirect_to :controller => 'home'
    end
  end


  def new_object_based_on_existing_one
    @existing_study =  Study.find(params[:id])
    @study = @existing_study.clone_with_associations

    unless @study.investigation.can_edit?
       @study.investigation = nil
      flash.now[:notice] = 'The investigation of the existing study cannot be viewed, please specify your own investigation!'
    end

    render :action => "new"

  end

  def new
    @study = Study.new
    @study.create_from_asset = params[:create_from_asset]
    @study.new_link_from_experiment = params[:new_link_from_experiment]
    investigation = nil
    investigation = Investigation.find(params[:investigation_id]) if params[:investigation_id]
    
    if investigation
      if investigation.can_edit?
        @study.investigation = investigation
      else
        flash.now[:error] = "You do not have permission to associate the new study with the investigation '#{investigation.title}'."
      end
    end
    investigations = Investigation.all.select &:can_view?
    respond_to do |format|
      if investigations.blank?
       flash.now[:notice] = "No investigation available, you have to create a new one before creating your study!"
      end
      format.html
    end
  end

  def edit
    @study=Study.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end

  # DELETE /study/1
  # DELETE /study/1.xml
  def destroy
    
    @study.destroy

    respond_to do |format|
      format.html { redirect_to(studies_url) }
      format.xml  { head :ok }
    end
  end

  
  def update
    @study=Study.find(params[:id])

    @study.attributes = params[:study]

    if params[:sharing]
      @study.policy_or_default
      @study.policy.set_attributes_with_sharing params[:sharing], @study.projects

    end

    respond_to do |format|
      if @study.save
        deliver_request_publish_approval params[:sharing], @study
        flash[:notice] = 'Study was successfully updated.'
        format.html { redirect_to(@study) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @study=Study.find(params[:id])
    @study.create_from_asset = params[:create_from_asset]
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@study.investigation,params[:deep]=='true',@study)}
      format.dot { render :text=>to_dot(@study.investigation,params[:deep]=='true',@study)}
      format.png { render :text=>to_png(@study.investigation,params[:deep]=='true',@study)}
    end

  end

  def create
    @study = Study.new(params[:study])

    @study.policy.set_attributes_with_sharing params[:sharing], @study.projects


  if @study.save
    deliver_request_publish_approval params[:sharing], @study
    if @study.new_link_from_experiment=="true"
      render :partial => "assets/back_to_singleselect_parent",:locals => {:child=>@study,:parent=>"experiment"}
    else
      respond_to do |format|
        flash[:notice] = 'The study was successfully created.<br/>'
        if @study.create_from_asset=="true"
          flash.now[:notice] << "Now you can create new experiment by clicking 'add an experiment' button"
          format.html { redirect_to study_path(:id=>@study,:create_from_asset=>@study.create_from_asset) }
        else
        format.html { redirect_to study_path(@study) }
        format.xml { render :xml => @study, :status => :created, :location => @study }
        end
      end
    end
  else
    respond_to do |format|
        format.html {render :action=>"new"}
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end
  end

  def investigation_selected_ajax

    if investigation_id = params[:investigation_id] and params[:investigation_id]!="0"
      investigation = Investigation.find(investigation_id)
      people=investigation.projects.collect(&:people).flatten
    end

    people||=[]

    render :update do |page|
      page.replace_html "person_responsible_collection",:partial=>"studies/person_responsible_list",:locals=>{:people=>people}
    end

  end

  def check_experiments_are_not_already_associated_with_another_study
    experiment_ids=params[:study][:experiment_ids]
    study_id=params[:id]    
    if (experiment_ids)
      valid = !experiment_ids.detect do |a_id|
        a=Experiment.find(a_id)
        !a.study.nil? && a.study_id.to_s!=study_id
      end
      if !valid
        unless valid
          error("Cannot add an experiment already associated with a Study", "is invalid (invalid Experiment)")
          return false
        end
      end
    end
  end
end
