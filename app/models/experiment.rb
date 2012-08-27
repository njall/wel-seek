require 'acts_as_authorized'

class Experiment < ActiveRecord::Base
  acts_as_isa

  def projects
    try_block {study.investigation.projects} || []
  end

  def project_ids
    projects.map(&:id)
  end

  alias_attribute :contributor, :owner
  acts_as_authorized

  def default_contributor
    User.current_user.try :person
  end

  acts_as_annotatable :name_field=>:title
  include Seek::Taggable

  belongs_to :institution
  has_and_belongs_to_many :samples
  belongs_to :experiment_type
  belongs_to :technology_type  
  belongs_to :study  
  belongs_to :owner, :class_name=>"Person"
  belongs_to :experiment_class
  has_many :experiment_organisms, :dependent=>:destroy
  has_many :organisms, :through=>:experiment_organisms
  has_many :strains, :through=>:experiment_organisms

  has_many :experiment_assets, :dependent => :destroy

  after_save :queue_background_reindexing if Seek::Config.solr_enabled
  
  def self.asset_sql(asset_class)
    asset_class_underscored = asset_class.underscore
    'SELECT '+ asset_class_underscored +'_versions.* FROM ' + asset_class_underscored + '_versions ' +
    'INNER JOIN experiment_assets ' +
    'ON experiment_assets.asset_id = ' + asset_class_underscored + '_id ' +
    'AND experiment_assets.asset_type = \'' + asset_class + '\' ' +
    'WHERE (experiment_assets.version = ' + asset_class_underscored + '_versions.version ' +
    'AND experiment_assets.experiment_id = #{self.id})'
  end

  #FIXME: These should be reversed, with the concrete version becoming the primary case, and versioned assets becoming secondary
  # i.e. - so data_files returnes [DataFile], and data_file_masters is replaced with versioned_data_files, returning [DataFile::Version]
  has_many :data_files, :class_name => "DataFile::Version", :finder_sql => self.asset_sql("DataFile")
  has_many :protocols, :class_name => "Protocol::Version", :finder_sql => self.asset_sql("Protocol")
  has_many :models, :class_name => "Model::Version", :finder_sql => self.asset_sql("Model")
  
  has_many :data_file_masters, :through => :experiment_assets, :source => :asset, :source_type => "DataFile"
  has_many :protocol_masters, :through => :experiment_assets, :source => :asset, :source_type => "Protocol"
  has_many :model_masters, :through => :experiment_assets, :source => :asset, :source_type => "Model"

  has_one :investigation,:through=>:study

  validates_presence_of :experiment_type
  validates_presence_of :technology_type, :unless=>:is_modelling?
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner
  validates_presence_of :experiment_class

  #a temporary store of added assets - see ExperimentReindexer
  attr_reader :pending_related_assets

  has_many :relationships, 
    :class_name => 'Relationship',
    :as => :subject,
    :dependent => :destroy
          
  searchable(:auto_index=>false) do
    text :description, :title, :searchable_tags, :organism_terms
    text :experiment_type do
        experiment_type.try :title
    end
    text :technology_type do
        technology_type.try :title
    end
    text :organisms do
        organisms.map{|o| o.title}
    end
    text :strains do
        strains.map{|s| s.title}
    end
  end if Seek::Config.solr_enabled

  def short_description
    type=experiment_type.nil? ? "No type" : experiment_type.title
   
    "#{title} (#{type})"
  end

  def can_delete? *args
    super && assets.empty? && related_publications.empty?
  end

  #returns true if this is a modelling class of experiment
  def is_modelling?
    return !experiment_class.nil? && experiment_class.key=="MODEL"
  end

  #returns true if this is an experimental class of experiment
  def is_experimental?
    return !experiment_class.nil? && experiment_class.key=="EXP"
  end    
  
  #Create or update relationship of this experiment to an asset, with a specific relationship type and version
  def relate(asset, r_type=nil)
    experiment_asset = experiment_assets.detect {|aa| aa.asset == asset}

    if experiment_asset.nil?
      experiment_asset = ExperimentAsset.new
      experiment_asset.experiment = self
    end
    
    experiment_asset.asset = asset
    experiment_asset.version = asset.version
    experiment_asset.relationship_type = r_type unless r_type.nil?
    experiment_asset.save if experiment_asset.changed?

    @pending_related_assets ||= []
    @pending_related_assets << asset

    return experiment_asset
  end

  #Associates and organism with the experiment
  #organism may be either an ID or Organism instance
  #strain_title should be the String for the strain
  #culture_growth should be the culture growth instance
  def associate_organism(organism,strain_title=nil,culture_growth_type=nil)
    organism = Organism.find(organism) if organism.kind_of?(Numeric) || organism.kind_of?(String)
    experiment_organism=ExperimentOrganism.new
    experiment_organism.experiment = self
    experiment_organism.organism = organism
    strain=nil
    if (strain_title && !strain_title.empty?)
      strain=organism.strains.find_by_title(strain_title)
      if strain.nil?
        strain=Strain.new(:title=>strain_title,:organism_id=>organism.id)
        strain.save!
      end
    end
    experiment_organism.culture_growth_type = culture_growth_type unless culture_growth_type.nil?
    experiment_organism.strain=strain

   

    existing = ExperimentOrganism.all.select{|ao|ao.organism==organism and ao.experiment == self and ao.strain==strain and ao.culture_growth_type==culture_growth_type}
    if existing.blank?
    self.experiment_organisms << experiment_organism
    end

  end
  
  def assets
    asset_masters.collect {|a| a.latest_version} |  (data_files + models + protocols)
  end

  def asset_masters
    data_file_masters + model_masters + protocol_masters
  end
  
  def related_publications
    self.relationships.select {|a| a.object_type == "Publication"}.collect { |a| a.object }
  end

  def related_asset_ids asset_type
    self.experiment_assets.select {|a| a.asset_type == asset_type}.collect { |a| a.asset_id }
  end

  def avatar_key
    type = is_modelling? ? "modelling" : "experimental"
    "experiment_#{type}_avatar"
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy
    new_object.protocol_masters = self.try(:protocol_masters)

    new_object.model_masters = self.try(:model_masters)
    new_object.sample_ids = self.try(:sample_ids)
    new_object.experiment_organisms = self.try(:experiment_organisms)

    return new_object
  end

  def validate
    #FIXME: allows at the moment until fixtures and factories are updated: JIRA: SYSMO-734
    errors.add_to_base "You cannot associate a modelling analysis with a sample" if is_modelling? && !samples.empty?
  end

  def organism_terms
    organisms.collect{|o| o.searchable_terms}.flatten
  end
end
