# SysMO: lib/acts_as_versioned_resource.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************

require 'project_compat'
module Acts #:nodoc:
  module VersionedResource #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_versioned_resource

        belongs_to :contributor, :polymorphic => true

        include ProjectCompat

        belongs_to :policy, :autosave => true

        class_eval do
          extend Acts::VersionedResource::SingletonMethods
        end
        include Acts::VersionedResource::InstanceMethods

      end

    end

    module SingletonMethods
    end

    module InstanceMethods
      # this method will take attributions' association and return a collection of resources,
      # to which the current resource is attributed
      def attributions_objects
        self.parent.attributions.collect { |a| a.object }
      end

      Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
        eval <<-END_EVAL
          def can_#{action}? user = User.current_user
            self.parent.can_perform? '#{action}', user
          end
        END_EVAL
      end

      #assumes all versioned resources are also taggable
      def tag_counts
          self.parent.tag_counts
      end

      #returns a list of the people that can manage this file
      #which will be the contributor, and those that have manage permissions
      def managers
        self.parent.managers
      end

      def attributions
        self.parent.attributions
      end

      def experiments(version_specific = false)
        if version_specific
          experiment_assets(true).collect { |a| a.asset }
        else
          self.parent.experiments
        end
      end

      def experiment_assets(version_specific = false)
        aa = self.parent.experiment_assets
        aa.select { |a| a.version == self.version } if version_specific
      end

      def creators
        self.parent.creators
      end

      def assets_creators
        self.parent.assets_creators
      end

      def is_asset?
        self.parent.is_asset?
      end

      def authorization_supported?
        self.parent.authorization_supported?
      end

      def defines_own_avatar?
        parent.defines_own_avatar?
      end

      def use_mime_type_for_avatar?
        parent.use_mime_type_for_avatar?
      end

      def avatar_key
        parent.avatar_key
      end

      def show_contributor_avatars?
        parent.show_contributor_avatars?
      end

      def annotations
        parent.annotations if parent.respond_to? :annotations
      end
    end
  end
end


ActiveRecord::Base.class_eval do
  include Acts::VersionedResource
end
