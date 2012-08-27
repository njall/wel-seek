require 'acts_as_ontology_view_helper'

module ExperimentsHelper
  
  include Stu::Acts::Ontology::ActsAsOntologyViewHelper  

  #experiments that haven't already been associated with a study
  def experiments_available_for_study_association
    Experiment.find(:all,:conditions=>['study_id IS NULL'])
  end

  #only data files authorised for show, and belonging to projects matching current_user
  def data_files_for_experiment_association
    data_files=DataFile.find(:all,:include=>:asset)
    data_files=data_files.select{|df| current_user.person.member_of?(df.projects)}
    Authorization.authorize_collection("view",data_files,current_user)
  end

  def experiment_organism_list_item experiment_organism
    result = link_to h(experiment_organism.organism.title),experiment_organism.organism
    if experiment_organism.strain
       result += " : "
       result += link_to h(experiment_organism.strain.title),experiment_organism.organism,{:class => "experiment_strain_info"}
    end
    if experiment_organism.culture_growth_type
      result += " (#{experiment_organism.culture_growth_type.title})"
    end
    return result
  end



  def authorised_experiments projects=nil
    authorised_assets(Experiment, projects, "edit")
  end

  def list_experiment_samples_and_organisms attribute,experiment_samples,experiment_organisms, none_text="Not Specified"

    result= "<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "

    result +="<span class='none_text'>#{none_text}</span>" if experiment_samples.blank? and experiment_organisms.blank?

    experiment_samples.each do |as|
      result += "<br/>" if as==experiment_samples.first
      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type

      if organism
      result += link_to h(organism.title),organism,{:class => "experiment_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "experiment_strain_info"}
      end

      if sample
        result += " : "
        result += link_to h(sample.title),sample
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as==experiment_samples.last and experiment_organisms.blank?
    end

    experiment_organisms.each do |ao|
      organism = ao.organism
      strain = ao.strain
      culture_growth_type = ao.culture_growth_type

       result += "<br/>" if experiment_samples.blank? and ao==experiment_organisms.first
      if organism
      result += link_to h(organism.title),organism,{:class => "experiment_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "experiment_strain_info"}
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless ao==experiment_organisms.last
    end
    result += "</p>"

    return result
  end

  def list_experiment_samples attribute,experiment_samples, none_text="Not Specified"

    result= "<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "

    result +="<span class='none_text'>#{none_text}</span>" if experiment_samples.blank?

    experiment_samples.each do |as|

      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type


      if organism
      result += link_to h(organism.title),organism,{:class => "experiment_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "experiment_strain_info"}
      end

      if sample
        result += " : "
        result += link_to h(sample.title),sample       
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as == experiment_samples.last

    end

    result += "</p>"
    return result
  end

  def list_experiment_organisms attribute,experiment_organisms,none_text="Not specified"
    result="<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "
    result +="<span class='none_text'>#{none_text}</span>" if experiment_organisms.empty?

    experiment_organisms.each do |ao|

     organism = ao.organism
     strain = ao.strain
     culture_growth_type = ao.culture_growth_type

        if organism
            result += link_to h(organism.title),organism,{:class => "experiment_organism_info"}
        end

        if strain
          result += " : "
          result += link_to h(strain.title),strain,{:class => "experiment_strain_info"}
        end
       

        if culture_growth_type
          result += " (#{culture_growth_type.title})"
        end
        result += ",<br/>" unless ao==experiment_organisms.last
      end

    result += "</p>"
    return result
  end

end
