require 'white_list_helper'

class ProjectsController < ApplicationController
  include WhiteListHelper
  include IndexPager


  before_filter :find_assets, :only=>[:index]
  before_filter :is_user_admin_auth, :except=>[:index, :show, :edit, :update, :request_institutions, :admin]
  before_filter :editable_by_user, :only=>[:edit,:update]
  before_filter :administerable_by_user, :only =>[:admin]
  before_filter :auth_params,:only=>[:update]
  before_filter :auth_institution_list_for_project_manager, :only => [:update]

  skip_before_filter :project_membership_required

  cache_sweeper :projects_sweeper,:only=>[:update,:create,:destroy]


  def redirect_if_disabled
    if !Seek::Config.projects_enabled
      redirect_to :controller => 'home'
    end
  end


  def auto_complete_for_organism_name
    render :json => Project.organism_counts.map(&:name).to_json
  end  

  def admin
    @project = Project.find(params[:id])
    
    respond_to do |format|
      format.html # admin.html.erb
    end
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    @project = Project.new

    possible_unsaved_data = "unsaved_#{@project.class.name}_#{@project.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and can *occasionally* be used by super-users -
        # regular users won't (and MUST NOT) be able to use these; it's not likely for admins
        # or super-users to modify these along with participating institutions - therefore,
        # it's better not to update these from session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for institutions that participate in this project would already be created, which is an
        # error (if the following line is ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:project].delete(:institution_ids)

        # update those attributes of a project that we want to be updated from the session
        @project.attributes = session[possible_unsaved_data][:project]
        @project.organism_list = session[possible_unsaved_data][:organism][:list] if session[possible_unsaved_data][:organism]
      end

      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    
    possible_unsaved_data = "unsaved_#{@project.class.name}_#{@project.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and can *occasionally* be used by super-users -
        # regular users won't (and MUST NOT) be able to use these; it's not likely for admins
        # or super-users to modify these along with participating institutions - therefore,
        # it's better not to update these from session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for institutions that participate in this project would already be created, which is an
        # error (if the following line is ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:project].delete(:institution_ids)
        
        # update those attributes of a project that we want to be updated from the session
        @project.attributes = session[possible_unsaved_data][:project]
        @project.organism_list = session[possible_unsaved_data][:organism][:list] if session[possible_unsaved_data][:organism]
      end
      
      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])

    @project.default_policy.set_attributes_with_sharing params[:sharing], [@project]


    respond_to do |format|
      if @project.save
        flash[:notice] = 'Project was successfully created.'
        format.html { redirect_to(@project) }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])
    #@project.work_groups.each{|wg| wg.destroy} if params[:project][:institutions].nil?
    
    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    avatar_id = params[:project].delete(:avatar_id).to_i
    @project.avatar_id = ((avatar_id.kind_of?(Numeric) && avatar_id > 0) ? avatar_id : nil)

    @project.default_policy = (@project.default_policy || Policy.default).set_attributes_with_sharing params[:sharing], [@project] if params[:sharing]

    respond_to do |format|
      if @project.update_attributes(params[:project])
        

        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
  end
  
  
  # returns a list of institutions for a project in JSON format
  def request_institutions
    # listing institutions for a project is public data, but still
    # we require login to protect from unwanted requests
    
    project_id = white_list(params[:id])
    institution_list = nil
    
    begin
      project = Project.find(project_id)
      institution_list = project.get_institutions_listing
      success = true
    rescue ActiveRecord::RecordNotFound
      # project wasn't found
      success = false
    end
    
    respond_to do |format|
      format.json {
        if success
          render :json => {:status => 200, :institution_list => institution_list }
        else
          render :json => {:status => 404, :error => "Couldn't find Project with ID #{project_id}."}
        end
      }
    end
  end

  private  

  def editable_by_user
    @project = Project.find(params[:id])
    unless User.admin_logged_in? || @project.can_be_edited_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end

  def administerable_by_user
    @project = Project.find(params[:id])
    unless User.admin_logged_in? || @project.can_be_administered_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end

  def auth_params
    restricted_params={:sharing => User.admin_logged_in?,
                       :site_root_uri => User.admin_logged_in?,
                       :site_username => User.admin_logged_in?,
                       :site_password => User.admin_logged_in?,
                       :institution_ids => (User.admin_logged_in? || @project.can_be_administered_by?(current_user))}
    restricted_params.each do |param, allowed|
      params[:project].delete(param) if params[:project] and not allowed
      params.delete param if params and not allowed
    end
  end

  def auth_institution_list_for_project_manager
     if (params[:project] and params[:project][:institution_ids])
      if User.project_manager_logged_in? && !User.admin_logged_in?
        institutions = []
        params[:project][:institution_ids].each do |id|
          institution = Institution.find_by_id(id)
          institutions << institution unless institution.nil?
        end
        institutions_of_this_project = @project.institutions
        institutions_of_no_project = Institution.all.select{|i| i.projects.empty?}
        allowed_institution_list =  (institutions_of_this_project + institutions_of_no_project).uniq
        flag = true
        institutions.each do |i|
          flag = false if !allowed_institution_list.include? i
        end
        if flag == false
          error("Insufficient privileges","is invalid (insufficient_privileges)")
        end
        return flag
      end
    end
  end
end
