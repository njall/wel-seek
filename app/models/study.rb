require 'acts_as_authorized'
class Study < ActiveRecord::Base  
  acts_as_isa

  attr_accessor :new_link_from_experiment

  belongs_to :investigation

  def projects
    investigation.try(:projects) || []
  end

  def project_ids
    projects.map(&:id)
  end

  acts_as_authorized

  has_many :experiments

  belongs_to :person_responsible, :class_name => "Person"


  validates_presence_of :investigation

  searchable do
    text :description,:title
  end if Seek::Config.solr_enabled

  #FIXME: see comment in Experiment about reversing these
  ["data_file","protocol","model"].each do |type|
    eval <<-END_EVAL
      def #{type}_masters
        experiments.collect{|a| a.send(:#{type}_masters)}.flatten.uniq
      end
      def #{type}s
        experiments.collect{|a| a.send(:#{type}s)}.flatten.uniq
      end
    END_EVAL
  end

  def can_delete? *args
    experiments.empty? && super
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy

    return new_object
  end

end
