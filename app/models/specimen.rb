require 'grouped_pagination'
require 'acts_as_authorized'
require 'subscribable'
class Specimen < ActiveRecord::Base
  include Subscribable

  acts_as_authorized
  acts_as_uniquely_identifiable

  before_save  :clear_garbage
  attr_accessor :from_biosamples


  has_many :samples
  has_many :activity_logs, :as => :activity_loggable
  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'

  belongs_to :institution
  belongs_to :culture_growth_type
  belongs_to :strain

  has_one :organism, :through=>:strain


  alias_attribute :description, :comments

  HUMANIZED_COLUMNS = Seek::Config.is_virtualliver ? {} : {:born => 'culture starting date', :culture_growth_type => 'culture type'}
  HUMANIZED_COLUMNS[:title] = "#{CELL_CULTURE_OR_SPECIMEN.capitalize} title"
  HUMANIZED_COLUMNS[:lab_internal_number] = "#{CELL_CULTURE_OR_SPECIMEN.capitalize} lab internal identifier"
  HUMANIZED_COLUMNS[:provider_id] = "provider's #{CELL_CULTURE_OR_SPECIMEN} identifier"

  validates_numericality_of :age, :only_integer => true, :greater_than=> 0, :allow_nil=> true, :message => "is not a positive integer"
  validates_presence_of :title,:lab_internal_number, :contributor,:strain

  validates_presence_of :institution if Seek::Config.is_virtualliver
  validates_uniqueness_of :title

  def self.protocol_sql()
  'SELECT protocol_versions.* FROM protocol_versions ' + 'INNER JOIN protocol_specimens ' +
  'ON protocol_specimens.protocol_id = protocol_versions.protocol_id ' +
  'WHERE (protocol_specimens.protocol_version = protocol_versions.version ' +
  'AND protocol_specimens.specimen_id = #{self.id})'
  end

  has_many :protocols,:class_name => "Protocol::Version",:finder_sql => self.protocol_sql()
  has_many :protocol_masters,:class_name => "ProtocolSpecimen"
  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  searchable do
    text :description,:title,:lab_internal_number
    text :culture_growth_type do
      culture_growth_type.try :title
    end
    text :strain do
      strain.try :title
    end
    text :institution do
      institution.try :name
    end if Seek::Config.is_virtualliver
  end if Seek::Config.solr_enabled

  def age_in_weeks
    if !age.nil?
      age.to_s + " (weeks)"
    end
  end

  def can_delete? user=User.current_user
    samples.empty? && super
  end

  def self.user_creatable?
    true
  end

  def clear_garbage
    if culture_growth_type.try(:title)=="in vivo"
      self.medium=nil
      self.culture_format=nil
      self.temperature=nil
      self.ph=nil
      self.confluency=nil
      self.passage=nil
      self.viability=nil
      self.purity=nil
    end
    if culture_growth_type.try(:title)=="cultured cell line"||culture_growth_type.try(:title)=="primary cell culture"
      self.sex=nil
      self.born=nil
      self.age=nil
    end

  end

  def strain_title
    self.strain.try(:title)
  end

  def strain_title= title
    existing = Strain.all.select{|s|s.title==title}.first
    if existing.blank?
      self.strain = Strain.create(:title=>title)
    else
      self.strain= existing
    end
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy
    new_object.protocol_masters = self.try(:protocol_masters)
    new_object.creators = self.try(:creators)
    new_object.project_ids = self.project_ids

    return new_object
  end


  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def born_info
    if born.nil?
      ''
    else
      if try(:born).hour == 0 && try(:born).min == 0 && try(:born).sec == 0
        try(:born).strftime('%d/%m/%Y')
      else
        try(:born).strftime('%d/%m/%Y @ %H:%M:%S')
      end
    end
  end

  def organism
    strain.try(:organism)
  end
end
