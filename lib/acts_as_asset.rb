
# SysMO: lib/acts_as_asset.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************
require 'acts_as_authorized'

module Acts #:nodoc:
  module Asset #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_asset?
      self.class.is_asset?
    end

    def is_downloadable_asset?
      is_asset? && is_downloadable?
    end

    module ClassMethods

      def acts_as_asset
        include Seek::Taggable

        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_annotatable :name_field=>:title
        acts_as_favouritable

        does_not_require_can_edit :last_used_at

        default_scope :order => "#{self.table_name}.updated_at DESC"

        validates_presence_of :title
        validates_presence_of :projects

        has_many :relationships,
                 :class_name => 'Relationship',
                 :as         => :subject,
                 :dependent  => :destroy

        has_many :attributions,
                 :class_name => 'Relationship',
                 :as         => :subject,
                 :conditions => {:predicate => Relationship::ATTRIBUTED_TO},
                 :dependent  => :destroy

        has_many :inverse_relationships,
                 :class_name => 'Relationship',
                 :as => :object,
                 :dependent => :destroy

        has_many :experiment_assets, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :experiments, :through => :experiment_assets

        has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'

        has_many :activity_logs, :as => :activity_loggable

        grouped_pagination :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

        class_eval do
          extend Acts::Asset::SingletonMethods
        end
        include Acts::Asset::InstanceMethods
        include BackgroundReindexing
        include Subscribable
      end



      def is_asset?
        include?(Acts::Asset::InstanceMethods)
      end



    end

    module SingletonMethods
    end

    module InstanceMethods

      def studies
        experiments.collect{|a| a.study}.uniq
      end

      # this method will take attributions' association and return a collection of resources,
      # to which the current resource is attributed
      def attributions
        self.relationships.select { |a| a.predicate == Relationship::ATTRIBUTED_TO }
      end


      def attributions_objects
        self.attributions.collect { |a| a.object }
      end

      def related_publications
        self.relationships.select { |a| a.object_type == "Publication" }.collect { |a| a.object }
      end


      def cache_remote_content_blob
        if self.content_blob && self.content_blob.url && self.projects.first
          begin
            p=self.projects.first
            p.decrypt_credentials
            downloader            =Jerm::DownloaderFactory.create p.name
            resource_type         = self.class.name.split("::")[0] #need to handle versions, e.g. Protocol::Version
            data_hash             = downloader.get_remote_data self.content_blob.url, p.site_username, p.site_password, resource_type
            self.content_blob.tmp_io_object = File.open data_hash[:data_tmp_path],"r"
            self.content_type     = data_hash[:content_type]
            self.content_blob.save
            self.save
          rescue Exception=>e
            puts "Error caching remote data for url=#{self.content_blob.url} #{e.message[0..50]} ..."
          end
        end
      end

      def project_experiments
        all_experiments=Experiment.all.select{|experiment| experiment.can_edit?(User.current_user)}.sort_by &:title
        all_experiments = all_experiments.select do |experiment|
          experiment.is_modelling?
        end if self.is_a? Model

        project_experiments = all_experiments.select { |df| User.current_user.person.projects.include?(df.project) }

        project_experiments
      end

      def experiment_type_titles
        experiments.collect{|a| a.experiment_type.try(:title)}.compact
      end

      def technology_type_titles
        experiments.collect{|a| a.technology_type.try(:title)}.compact
      end

    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Asset
end
