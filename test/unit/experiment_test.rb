require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  fixtures :all


  test "shouldnt edit the experiment" do
    user = users(:aaron)
    experiment = experiments(:modelling_experiment_with_data_and_relationship)
    assert_equal false, experiment.can_edit?(user)
  end

  test "protocols association" do
    experiment=experiments(:metabolomics_experiment)
    assert_equal 2,experiment.protocols.size
    assert experiment.protocols.include?(protocols(:my_first_protocol).versions.first)
    assert experiment.protocols.include?(protocols(:protocol_with_fully_public_policy).versions.first)
  end

  test "is_asset?" do
    assert !Experiment.is_asset?
    assert !experiments(:metabolomics_experiment).is_asset?
  end

  test "sort by updated_at" do
    assert_equal Experiment.find(:all).sort_by { |a| a.updated_at.to_i * -1 }, Experiment.find(:all)
  end

  test "authorization supported?" do
    assert Experiment.authorization_supported?
    assert experiments(:metabolomics_experiment).authorization_supported?
  end

  test "avatar_key" do
    assert_equal "experiment_experimental_avatar",experiments(:metabolomics_experiment).avatar_key
    assert_equal "experiment_modelling_avatar",experiments(:modelling_experiment_with_data_and_relationship).avatar_key
  end

  test "is_modelling" do
    experiment=experiments(:metabolomics_experiment)
    User.current_user = experiment.contributor.user
    assert !experiment.is_modelling?
    experiment.experiment_class=experiment_classes(:modelling_experiment_class)
    experiment.samples = []
    experiment.save!
    assert experiment.is_modelling?
  end
  
  test "title_trimmed" do
    User.with_current_user Factory(:user) do
      experiment=Factory :experiment,
                    :contributor => User.current_user.person,
                    :title => " test"
      experiment.save!
      assert_equal "test",experiment.title
    end
  end

  test "is_experimental" do
    experiment=experiments(:metabolomics_experiment)
    User.current_user = experiment.contributor.user
    assert experiment.is_experimental?
    experiment.experiment_class=experiment_classes(:modelling_experiment_class)
    experiment.samples = []
    experiment.save!
    assert !experiment.is_experimental?
  end

  test "related investigation" do
    experiment=experiments(:metabolomics_experiment)
    assert_not_nil experiment.investigation
    assert_equal investigations(:metabolomics_investigation),experiment.investigation
  end

  test "related project" do
    experiment=experiments(:metabolomics_experiment)
    assert !experiment.projects.empty?
    assert experiment.projects.include?(projects(:sysmo_project))
  end
  

  test "validation" do
    User.with_current_user Factory(:user) do
    experiment=new_valid_experiment
    
    assert experiment.valid?


    experiment.title=""
    assert !experiment.valid?

    experiment.title=nil
    assert !experiment.valid?

    experiment.title=experiments(:metabolomics_experiment).title
    assert experiment.valid? #can have duplicate titles

    experiment.title="test"
    experiment.experiment_type=nil
    assert !experiment.valid?

    experiment.experiment_type=experiment_types(:metabolomics)

    assert experiment.valid?

    experiment.study=nil
    assert !experiment.valid?
    experiment.study=studies(:metabolomics_study)

    experiment.technology_type=nil
    assert !experiment.valid?

    experiment.technology_type=technology_types(:gas_chromatography)
    assert experiment.valid?

    experiment.owner=nil
    assert !experiment.valid?

    experiment.owner=people(:person_for_model_owner)

      #an modelling experiment can be valid without a technology type, sample or organism
    experiment.experiment_class=experiment_classes(:modelling_experiment_class)
    experiment.technology_type=nil
      experiment.samples = []
    assert experiment.valid?
    
    #an experimental experiment can be invalid without a sample
    experiment.experiment_class=experiment_classes(:experimental_experiment_class)
    experiment.technology_type=nil
    experiment.samples = []
    assert !experiment.valid?
    end
  end

  test "associated publication" do
    assert_equal 1, experiments(:experiment_with_a_publication).related_publications.size
  end

  test "can delete?" do
    user = User.current_user = Factory(:user)
    assert Factory(:experiment, :contributor => user.person).can_delete?

    experiment = Factory(:experiment, :contributor => user.person)
    experiment.relate Factory(:data_file, :contributor => user)
    assert !experiment.can_delete?

    experiment = Factory(:experiment, :contributor => user.person)
    experiment.relate Factory(:protocol, :contributor => user)
    assert !experiment.can_delete?

    experiment = Factory(:experiment, :contributor => user.person)
    experiment.relate Factory(:model, :contributor => user)
    assert !experiment.can_delete?

    pal = Factory :pal
    #create an experiment with projects = to the projects for which the pal is a pal
    experiment = Factory(:experiment,
                    :study => Factory(:study,
                                      :investigation => Factory(:investigation,
                                                                :projects => pal.projects)))
    assert !experiment.can_delete?(pal.user)
    
    assert !experiments(:experiment_with_a_publication).can_delete?(users(:model_owner))
  end

  test "assets" do
    experiment=experiments(:metabolomics_experiment)
    assert_equal 3,experiment.assets.size,"should be 2 protocols and 1 data file"
  end

  test "protocols" do
    experiment=experiments(:metabolomics_experiment)
    assert_equal 2,experiment.protocols.size
    assert experiment.protocols.include?(protocols(:my_first_protocol).find_version(1))
    assert experiment.protocols.include?(protocols(:protocol_with_fully_public_policy).find_version(1))
  end

  test "data_files" do
    experiment=experiments(:metabolomics_experiment)
    assert_equal 1,experiment.data_files.size
    assert experiment.data_files.include?(data_files(:picture).find_version(1))
  end
  
  test "can relate data files" do
    experiment = experiments(:metabolomics_experiment)
    User.with_current_user experiment.contributor.user do
      assert_difference("Experiment.find_by_id(experiment.id).data_files.count") do
        experiment.relate(data_files(:viewable_data_file), relationship_types(:test_data))
      end
    end
  end
  
  test "relate new version of protocol" do
    User.with_current_user Factory(:user) do
      experiment=Factory :experiment, :contributor => User.current_user.person
      experiment.save!
      protocol=protocols(:protocol_with_all_sysmo_users_policy)
      assert_difference("Experiment.find_by_id(experiment.id).protocols.count", 1) do
        assert_difference("ExperimentAsset.count", 1) do
          experiment.relate(protocol)
        end
      end
      experiment.reload
      assert_equal 1, experiment.experiment_assets.size
      assert_equal protocol.version, experiment.experiment_assets.first.versioned_asset.version

      User.current_user = protocol.contributor
      protocol.save_as_new_version

      assert_no_difference("Experiment.find_by_id(experiment.id).protocols.count") do
        assert_no_difference("ExperimentAsset.count") do
          experiment.relate(protocol)
        end
      end

      experiment.reload
      assert_equal 1, experiment.experiment_assets.size
      assert_equal protocol.version, experiment.experiment_assets.first.versioned_asset.version
    end
  end

  test "organisms association" do
    experiment=experiments(:metabolomics_experiment)
    assert_equal 2,experiment.experiment_organisms.count
    assert_equal 2,experiment.organisms.count
    assert experiment.organisms.include?(organisms(:yeast))
    assert experiment.organisms.include?(organisms(:Saccharomyces_cerevisiae))
  end

  test "associate organism" do
    experiment=experiments(:metabolomics_experiment)
    User.current_user = experiment.contributor
    organism=organisms(:yeast)
    #test with numeric ID
    assert_difference("ExperimentOrganism.count") do
      experiment.associate_organism(organism.id)
    end

    #with String ID
    assert_no_difference("ExperimentOrganism.count") do
      experiment.associate_organism(organism.id.to_s)
    end

    #with Organism object
    assert_no_difference("ExperimentOrganism.count") do
      experiment.associate_organism(organism)
    end

    #with a culture growth
    experiment.experiment_organisms.clear
    experiment.save!
    cg=culture_growth_types(:batch)
    assert_difference("ExperimentOrganism.count") do
      experiment.associate_organism(organism,nil,cg)
    end
    experiment.reload
    assert_equal cg,experiment.experiment_organisms.first.culture_growth_type

  end

  test "disassociating organisms removes ExperimentOrganism" do
    experiment=experiments(:metabolomics_experiment)
    User.current_user = experiment.contributor
    assert_equal 2,experiment.experiment_organisms.count
    assert_difference("ExperimentOrganism.count",-2) do
      experiment.experiment_organisms.clear
      experiment.save!
    end
    
  end

  test "associate organism with strain" do
    experiment=experiments(:metabolomics_experiment2)
    organism=organisms(:Streptomyces_coelicolor)
    assert_equal 0,experiment.experiment_organisms.count,"This test relies on this experiment having no organisms"
    assert_equal 0,organism.strains.count, "This test relies on this organism having no strains"

    assert_difference("ExperimentOrganism.count") do
      assert_difference("Strain.count") do
        experiment.associate_organism(organism,"FFFF")
      end
    end

    assert_no_difference("ExperimentOrganism.count") do
      assert_no_difference("Strain.count") do
        experiment.associate_organism(organism,"FFFF")
      end
    end

    organism=organisms(:yeast)
    assert_difference("ExperimentOrganism.count") do
      assert_difference("Strain.count") do
        experiment.associate_organism(organism,"FFFF")
      end
    end

  end

  test "test uuid generated" do
    a = experiments(:metabolomics_experiment)
    assert_nil a.attributes["uuid"]
    a.save
    assert_not_nil a.attributes["uuid"]
  end 

  test "uuid doesn't change" do
    x = experiments(:metabolomics_experiment)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  def new_valid_experiment
    Experiment.new(:title=>"test",
      :experiment_type=>experiment_types(:metabolomics),
      :technology_type=>technology_types(:gas_chromatography),
      :study => studies(:metabolomics_study),
      :owner => people(:person_for_model_owner),
      :experiment_class => experiment_classes(:experimental_experiment_class),
      :samples => [Factory :sample]
    )

  end

  test "contributing_user" do
      experiment = Factory :experiment
      assert experiment.contributor
      assert_equal experiment.contributor.user, experiment.contributing_user
  end
end
