module Seek
  class ContentStats
    
    class ProjectStats
      attr_accessor :project,:protocols,:data_files,:models,:publications,:people,:experiments,:studies,:investigations, :user
      
      def initialize
        @user=User.first
      end
      
      def data_files_size
        assets_size data_files
      end
      
      def protocols_size
        assets_size protocols
      end
      
      def models_size
        assets_size models
      end
      
      def visible_data_files
        authorised_assets data_files,"view"
      end
      
      def visible_protocols
        authorised_assets protocols,"view"
      end
      
      def visible_models
        authorised_assets models,"view"
      end
      
      def accessible_data_files
        authorised_assets data_files,"download"
      end
      
      def accessible_protocols
        authorised_assets protocols,"download"
      end
      
      def accessible_models
        authorised_assets models,"download"
      end
      
      def registered_people
        people.select{|p| !p.user.nil?}
      end
      
      private

      def authorised_assets assets,action
        assets.select{|asset| asset.can_perform? action, @user}
      end
      
      def assets_size assets
        size=0
        assets.each do |asset|
          size += asset.content_blob.data.size unless asset.content_blob.data.nil?
        end
        return size
      end
    end  

    def self.generate    
      result=[]    
      Project.all.each do |project|
        project_stats=ProjectStats.new
        project_stats.project=project
        project_stats.protocols=project.protocols
        project_stats.models=project.models
        project_stats.data_files=project.data_files
        project_stats.publications=project.publications
        project_stats.people=project.people
        project_stats.experiments=project.experiments
        project_stats.studies=project.studies
        project_stats.investigations=project.investigations
        result << project_stats           
      end
      return result
    end
    
  end
end