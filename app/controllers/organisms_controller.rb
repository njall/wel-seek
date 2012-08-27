class OrganismsController < ApplicationController
  before_filter :redirect_me
  before_filter :login_required,:except=>[:show,:index,:visualise]
  before_filter :is_user_admin_auth,:only=>[:edit,:update,:new,:create,:destroy]
  before_filter :find_organism,:only=>[:show,:edit,:more_ajax,:visualise,:destroy]
  layout "main",:except=>:visualise
  
  cache_sweeper :organisms_sweeper,:only=>[:update,:create,:destroy]

  include BioPortal::RestAPI

  def redirect_me
    redirect_to :controller => 'home'
  end

  def show
    respond_to do |format|
      format.html
      format.xml
    end
  end
  
  def destroy
    respond_to do |format|
      if @organism.can_delete? && @organism.destroy
        flash[:notice] = 'Organism was successfully removed.'
        format.html { redirect_to root_path }        
      else
        flash[:error] = "Unable to delete organism"
        format.html { render :action => "show" }       
      end
    end
  end

  def index
    @organisms=Organism.all
    respond_to do |format|
      format.xml
    end
  end

  def visualise
    respond_to do |format|
      format.html
    end
  end

  def new
    @organism=Organism.new
    respond_to do |format|
      format.html
    end
  end

  def search_ajax
    pagenum=params[:pagenum]
    pagenum||=1
    search_term=params[:search_term]
    results,pages = search search_term,{:isexactmatch=>0,:pagesize=>50,:pagenum=>pagenum,:ontologyids=>"1132",:apikey=>Seek::Config.bioportal_api_key}
    render :update do |page|
      if results
        page.replace_html 'search_results',:partial=>"search_results",:object=>results,:locals=>{:pages=>pages,:pagenum=>pagenum,:search_term=>search_term}
      else
        page.replace_html 'search_results',:text=>"Nothing found"
      end
    end
  end

  def more_ajax    
    concept = @organism.concept
    render :update do |page|
      if concept
        page.replace_html 'bioportal_more',:partial=>"concept",:object=>concept
      else
        page.replace_html 'bioportal_more',:text=>"Nothing found"
      end
    end
  end

  def create
    @organism = Organism.new(params[:organism])
    respond_to do |format|
      if @organism.save
        flash[:notice] = 'Organism was successfully created.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @organism = Organism.find(params[:id])

    respond_to do |format|
      if @organism.update_attributes(params[:organism])
        flash[:notice] = 'Organism was successfully updated.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  private

  def find_organism
    begin
      @organism=Organism.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "The Organism selected does not exist"
        format.html { redirect_to root_path }
      end    
    end
  end
  
end
