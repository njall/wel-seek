
class Investigation < ActiveRecord::Base    
  acts_as_isa
  acts_as_authorized


  attr_accessor :new_link_from_study

  has_many :studies


  validates_presence_of :projects
  validates_presence_of :title

  has_many :experiments,:through=>:studies

  searchable do
    text :description,:title
  end if Seek::Config.solr_enabled

  def can_delete? *args
    studies.empty? && super
  end
  
  #FIXME: see comment in Experiment about reversing these
  ["data_file","protocol","model"].each do |type|
    eval <<-END_EVAL
      def #{type}_masters
        studies.collect{|study| study.send(:#{type}_masters)}.flatten.uniq
      end
      def #{type}s
        studies.collect{|study| study.send(:#{type}s)}.flatten.uniq
      end
    END_EVAL
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy
    new_object.project_ids= self.project_ids
    return new_object
  end

end
