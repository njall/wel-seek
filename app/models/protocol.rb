require 'acts_as_asset'
require 'explicit_versioning'
require 'grouped_pagination'
require 'title_trimmer'
require 'acts_as_versioned_resource'

class Protocol < ActiveRecord::Base

  acts_as_asset
  acts_as_trashable

  title_trimmer

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Protocol with such title."

  searchable(:ignore_attribute_changes_of=>[:updated_at,:last_used_at]) do
    text :description, :title, :original_filename,:searchable_tags,:exp_conditions_search_fields,:experiment_type_titles,:technology_type_titles
  end if Seek::Config.solr_enabled

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
               
  has_many :experimental_conditions, :conditions =>  'experimental_conditions.protocol_version = #{self.version}'

  has_many :protocol_specimens
  has_many :specimens,:through=>:protocol_specimens

  explicit_versioning(:version_column => "version") do
    
    acts_as_versioned_resource
    
    belongs_to :content_blob
    
    has_many :experimental_conditions, :primary_key => "protocol_id", :foreign_key => "protocol_id", :conditions =>  'experimental_conditions.protocol_version = #{self.version}'
    
  end

  # get a list of Protocols with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all = Protocol.all_authorized_for "view",user
    with_contributors = all.collect{ |d|
        contributor = d.contributor;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name
        }
    }
    return with_contributors.to_json
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end


  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end

  #experimental_conditions, and related compound text that should be included in search
  def exp_conditions_search_fields
    flds = experimental_conditions.collect do |ec|
      [ec.measured_item.title,
       ec.substances.collect do |sub|
         #FIXME: this makes the assumption that the synonym.substance appears like a Compound
         sub = sub.substance if sub.is_a?(Synonym)
         [sub.title] |
             (sub.respond_to?(:synonyms) ? sub.synonyms.collect { |syn| syn.title } : []) |
             (sub.respond_to?(:mappings) ? sub.mappings.collect { |mapping| ["CHEBI:#{mapping.chebi_id}", mapping.chebi_id, mapping.sabiork_id.to_s, mapping.kegg_id] } : [])
       end
      ]
    end
    flds.flatten.uniq
  end
    
end
