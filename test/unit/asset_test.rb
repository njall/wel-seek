require 'test_helper'

class AssetTest < ActiveSupport::TestCase
  fixtures :all
  include ApplicationHelper

  test "default contributor or nil" do
    User.current_user = users(:owner_of_my_first_protocol)
    model = Model.new(Factory.attributes_for(:model).tap{|h|h[:contributor] = nil})
    assert_equal users(:owner_of_my_first_protocol),model.contributor
    model.contributor = nil
    model.save!
    assert_equal nil,model.contributor
    model = Model.find(model.id)
    assert_equal nil,model.contributor
  end

  test "experiment type titles" do
    df = Factory :data_file
    experiment = Factory :experimental_experiment,:experiment_type=>Factory(:experiment_type,:title=>"aaa")
    experiment2 = Factory :modelling_experiment,:experiment_type=>Factory(:experiment_type,:title=>"bbb")

    disable_authorization_checks do
      experiment.relate(df)
      experiment2.relate(df)
      experiment.reload
      experiment2.reload
      df.reload
    end

    assert_equal ["aaa","bbb"],df.experiment_type_titles.sort
    m=Factory :model
    assert_equal [],m.experiment_type_titles

  end

  test "tech type titles" do
    df = Factory :data_file
    experiment = Factory :experimental_experiment,:technology_type=>Factory(:technology_type,:title=>"aaa")
    experiment2 = Factory :modelling_experiment,:technology_type=>Factory(:technology_type,:title=>"bbb")
    experiment3 = Factory :modelling_experiment,:technology_type=>nil

    disable_authorization_checks do
      experiment.relate(df)
      experiment2.relate(df)
      experiment3.relate(df)
      experiment.reload
      experiment2.reload
      df.reload
    end

    assert_equal ["aaa","bbb"],df.technology_type_titles.sort
    m=Factory :model
    assert_equal [],m.technology_type_titles

  end

  test "classifying and authorizing resources" do
    resource_array = []
    protocol=protocols(:my_first_protocol)
    model=models(:teusink)
    data_file=data_files(:picture)
    user=users(:owner_of_my_first_protocol)
    
    protocol_version1 = protocol.find_version(1)
    model_version2 = model.find_version(2)
    
    resource_array << protocol_version1
    resource_array << model_version2
    resource_array << data_file
    
    assert_equal 1, protocol.version
    assert_equal 2, model.version
    assert_equal 1, data_file.version
    
        
    result = Asset.classify_and_authorize_resources(resource_array, true, user)    
    
    assert_equal 3, result.length
    
    assert result["Protocol"].include?(protocol_version1)
    assert result["Model"].include?(model_version2)
    assert result["DataFile"].include?(data_file)
  end

  test "is_published?" do
    User.with_current_user Factory(:user) do
      public_protocol=Factory(:protocol,:policy=>Factory(:public_policy,:access_type=>Policy::ACCESSIBLE))
      private_model=Factory(:model,:policy=>Factory(:public_policy,:access_type=>Policy::VISIBLE))
      public_datafile=Factory(:data_file,:policy=>Factory(:public_policy))
      registered_only_experiment=Factory(:experiment,:policy=>Factory(:public_policy, :sharing_scope=>Policy::ALL_SYSMO_USERS))

      assert public_protocol.is_published?
      assert !private_model.is_published?
      assert public_datafile.is_published?
      assert !registered_only_experiment.is_published?
    end
  end

  test "publish" do
    user = Factory(:user)
    private_model=Factory(:model,:contributor=>user,:policy=>Factory(:public_policy,:access_type=>Policy::VISIBLE))
    User.with_current_user user do
      assert private_model.can_manage?,"Should be able to manage this model for the test to work"
      assert private_model.publish!
    end
    private_model.reload
    assert_equal Policy::ACCESSIBLE,private_model.policy.access_type
    assert_equal Policy::EVERYONE,private_model.policy.sharing_scope

  end

  test "is publishable" do
    assert Factory(:protocol).is_publishable?
    assert Factory(:model).is_publishable?
    assert Factory(:data_file).is_publishable?
    assert !Factory(:experiment).is_publishable?
    assert !Factory(:investigation).is_publishable?
    assert !Factory(:study).is_publishable?
    assert !Factory(:event).is_publishable?
    assert !Factory(:publication).is_publishable?
  end

  test "managers" do
    person=Factory(:person)
    person2=Factory(:person,:first_name=>"fred",:last_name=>"bloggs")
    user=Factory(:user)
    protocol=Factory(:protocol,:contributor=>person)
    assert_equal 1,protocol.managers.count
    assert protocol.managers.include?(person)

    df=Factory(:data_file,:contributor=>user)
    assert_equal 1,df.managers.count
    assert df.managers.include?(user.person)

    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => user, :access_type => Policy::MANAGING, :policy => policy)
    policy.permissions << Factory(:permission, :contributor => person, :access_type => Policy::EDITING, :policy => policy)
    experiment=Factory(:experiment,:policy=>policy,:contributor=>person2)
    assert_equal 2,experiment.managers.count
    assert experiment.managers.include?(user.person)
    assert experiment.managers.include?(person2)

    #this is liable to change when Project contributors are handled
    p1=Factory(:project)
    p2=Factory(:project)
    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => p1, :access_type => Policy::MANAGING, :policy => policy)
    model=Factory(:model,:policy=>policy,:contributor=>p2)
    assert model.managers.empty?
  end

  test "tags as text array" do
    model = Factory :model
    u = Factory :user
    Factory :tag,:annotatable=>model,:source=>u,:value=>"aaa"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"bbb"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"ddd"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"ccc"
    assert_equal ["aaa","bbb","ccc","ddd"],model.tags_as_text_array.sort

    p = Factory :person
    Factory :expertise,:annotatable=>p,:source=>u,:value=>"java"
    Factory :tool,:annotatable=>p,:source=>u,:value=>"trowel"
    assert_equal ["java","trowel"],p.tags_as_text_array.sort
  end


end