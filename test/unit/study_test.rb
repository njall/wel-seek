require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  
  fixtures :all

  test "associations" do
    study=studies(:metabolomics_study)
    assert_equal "A Metabolomics Study",study.title

    assert_not_nil study.experiments
    assert_equal 1,study.experiments.size
    assert !study.investigation.projects.empty?

    assert study.experiments.include?(experiments(:metabolomics_experiment))
    
    assert_equal projects(:sysmo_project),study.investigation.projects.first
    assert_equal projects(:sysmo_project),study.projects.first
    
    assert_equal experiment_types(:metabolomics),study.experiments.first.experiment_type

  end

  test "sort by updated_at" do
    assert_equal Study.find(:all).sort_by { |s| s.updated_at.to_i * -1 }, Study.find(:all)
  end

  #only authorized people can delete a study, and a study must have no experiments
  test "can delete" do
    project_member = Factory :person
    study = Factory :study, :contributor => Factory(:person), :investigation => Factory(:investigation, :projects => project_member.projects)
    assert !study.can_delete?(Factory(:user))
    assert !study.can_delete?(project_member.user)
    assert study.can_delete?(study.contributor)

    study=Factory :study, :contributor => Factory(:person), :experiments => [Factory :experiment]
    assert !study.can_delete?(study.contributor)
  end

  test "protocols through experiments" do
    study=studies(:metabolomics_study)
    assert_equal 2,study.protocols.size
    assert study.protocols.include?(protocols(:my_first_protocol).versions.first)
    assert study.protocols.include?(protocols(:protocol_with_fully_public_policy).versions.first)
    
    #study with 2 experiments that have overlapping protocols. Checks that the protocols aren't dupliced.
    study=studies(:study_with_overlapping_experiment_protocols)
    assert_equal 3,study.protocols.size
    assert study.protocols.include?(protocols(:my_first_protocol).versions.first)
    assert study.protocols.include?(protocols(:protocol_with_fully_public_policy).versions.first)
    assert study.protocols.include?(protocols(:protocol_for_test_with_workgroups).versions.first)
  end

  test "person responisble" do
    study=studies(:metabolomics_study)
    assert_equal people(:person_without_group),study.person_responsible
  end

  test "project from investigation" do
    study=studies(:metabolomics_study)
    assert_equal projects(:sysmo_project), study.projects.first
    assert_not_nil study.projects.first.name
  end

  test "title trimmed" do
    s=Factory(:study, :title=>" title")
    assert_equal("title",s.title)
  end
  

  test "validation" do
    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation))
    assert s.valid?

    s.title=nil
    assert !s.valid?
    s.title
    assert !s.valid?

    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation))
    s.investigation=nil
    assert !s.valid?

  end

  test "study with 1 experiment" do
    study=studies(:study_with_experiment_with_public_private_protocols_and_datafile)
    assert_equal 1,study.experiments.size,"This study must have only one experiment - do not modify its fixture"
  end
  
  test "test uuid generated" do
    s = studies(:metabolomics_study)
    assert_nil s.attributes["uuid"]
    s.save
    assert_not_nil s.attributes["uuid"]
  end 
  
  test "uuid doesn't change" do
    x = studies(:metabolomics_study)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
end
