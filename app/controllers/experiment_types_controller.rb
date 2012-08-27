class ExperimentTypesController < ApplicationController

  before_filter :check_allowed_to_manage_types, :except=>[:show,:index]

  def show
    @experiment_type = ExperimentType.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def new
    @experiment_type=ExperimentType.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @experiment_type }
    end
  end
  
  def index
    @experiment_types=ExperimentType.all
    respond_to do |format|
      format.xml
    end
  end
  
  def manage
    @experiment_types = ExperimentType.all
    #@experiment_type = ExperimentType.last

    respond_to do |format|
      format.html
      format.xml {render :xml=>@experiment_types}
    end
  end
  
  def edit
    @experiment_type=ExperimentType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @experiment_type }
    end
  end
  
  def create
    @experiment_type = ExperimentType.new(:title => params[:experiment_type][:title])
    @experiment_type.parents = params[:experiment_type][:parent_id].collect {|p_id| ExperimentType.find_by_id(p_id)}
    #@experiment_type.owner=current_user.person    
    
    respond_to do |format|
      if @experiment_type.save        
        flash[:notice] = 'Experiment type was successfully created.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @experiment_type, :status => :created, :location => @experiment_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @experiment_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @experiment_type=ExperimentType.find(params[:id])

    respond_to do |format|
      if @experiment_type.update_attributes(:title => params[:experiment_type][:title])
        unless params[:experiment_type][:parent_id] == @experiment_type.parents.collect {|par| par.id}
          @experiment_type.parents = params[:experiment_type][:parent_id].collect {|p_id| ExperimentType.find_by_id(p_id)}
        end
        flash[:notice] = 'Experiment type was successfully updated.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        format.html { redirect_to(:action => 'edit') }
        format.xml  { render :xml => @experiment_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy    
    @experiment_type=ExperimentType.find(params[:id])
    
    respond_to do |format|
      if @experiment_type.experiments.empty? && @experiment_type.get_child_experiments.empty? && @experiment_type.children.empty?
        @experiment_type.destroy
        flash[:notice] = 'Experiment type was deleted.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        if !@experiment_type.children.empty?
          flash[:error]="Unable to delete experiment types with children" 
        elsif !@experiment_type.get_child_experiments.empty?
          flash[:error]="Unable to delete experiment type due to reliance from #{@experiment_type.get_child_experiments.count} existing experiments on child experiment types"
        elsif !@experiment_type.experiments.empty?
          flash[:error]="Unable to delete experiment type due to reliance from #{@experiment_type.get_child_experiments.count} existing experiments"        
        end
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @experiment_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end