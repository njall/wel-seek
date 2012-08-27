require 'test_helper'


class ModelTest < ActiveSupport::TestCase
  fixtures :all    

  test "assocations" do
    model=models(:teusink)
    jws_env=recommended_model_environments(:jws)

    assert_equal jws_env,model.recommended_environment

    assert_equal "Teusink",model.title

    blob=content_blobs(:teusink_blob)
    assert_equal blob,model.content_blob
  end

  test "type detection" do
    model = models(:teusink)
    assert model.is_sbml?
    assert model.is_jws_supported?
    assert !model.is_dat?

    model = models(:jws_model)
    assert !model.is_sbml?
    assert model.is_jws_supported?
    assert model.is_dat?

    model = models(:non_sbml_xml)
    assert !model.is_sbml?
    assert !model.is_jws_supported?
    assert !model.is_dat?

    #should also be able to handle versions
    model = models(:teusink).latest_version
    assert model.is_sbml?
    assert model.is_jws_supported?
    assert !model.is_dat?

    model = models(:jws_model).latest_version
    assert !model.is_sbml?
    assert model.is_jws_supported?
    assert model.is_dat?

    model = models(:non_sbml_xml).latest_version
    assert !model.is_sbml?
    assert !model.is_jws_supported?
    assert !model.is_dat?
  end

  test "experiment association" do
    model = models(:teusink)
    experiment = experiments(:modelling_experiment_with_data_and_relationship)
    experiment_asset = experiment_assets(:metabolomics_experiment_asset1)
    assert_not_equal experiment_asset.asset, model
    assert_not_equal experiment_asset.experiment, experiment
    experiment_asset.asset = model
    experiment_asset.experiment = experiment
    User.with_current_user(model.contributor){experiment_asset.save!}
    experiment_asset.reload
    assert experiment_asset.valid?
    assert_equal experiment_asset.asset, model
    assert_equal experiment_asset.experiment, experiment

  end

  test "sort by updated_at" do
    assert_equal Model.find(:all).sort_by { |m| m.updated_at.to_i * -1 }, Model.find(:all)
  end

  test "validation" do
    asset=Model.new :title=>"fred",:projects=>[projects(:sysmo_project)]
    assert asset.valid?

    asset=Model.new :projects=>[projects(:sysmo_project)]
    assert !asset.valid?

    asset=Model.new :title=>"fred"
    assert !asset.valid?
  end

  test "is asset?" do
    assert Model.is_asset?
    assert models(:teusink).is_asset?
    
    assert model_versions(:teusink_v1).is_asset?
  end

  test "avatar_key" do
    assert_equal "model_avatar",models(:teusink).avatar_key
    assert_equal "model_avatar",model_versions(:teusink_v1).avatar_key
  end

  test "authorization supported?" do
    assert Model.authorization_supported?
    assert models(:teusink).authorization_supported?
    assert model_versions(:teusink_v1).authorization_supported?
  end
  
  test "projects" do
    model=models(:teusink)
    p=projects(:sysmo_project)
    assert_equal [p],model.projects
    assert_equal [p],model.latest_version.projects
  end

  test "cache_remote_content" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/Teusink.xml","http://mockedlocation.com/teusink.xml"

    model = Factory :model,
        :content_blob => ContentBlob.new(:url=>"http://mockedlocation.com/teusink.xml"),
        :original_filename => "teusink.xml"

    assert !model.content_blob.file_exists?

    model.cache_remote_content_blob

    assert model.content_blob.file_exists?

  end
  
  def test_defaults_to_private_policy
    model=Model.new Factory.attributes_for(:model, :policy => nil)
    model.save!
    model.reload
    assert_not_nil model.policy
    assert_equal Policy::PRIVATE, model.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, model.policy.access_type
    assert_equal false,model.policy.use_whitelist
    assert_equal false,model.policy.use_blacklist
    assert model.policy.permissions.empty?
  end

  test "creators through asset" do
    model=models(:teusink)
    assert_not_nil model.creators
    assert_equal 2,model.creators.size
    assert model.creators.include?(people(:pal))
    assert model.creators.include?(people(:person_for_model_owner))
    
  end
  
  test "titled trimmed" do
    model=models(:teusink)
    model.title=" space"
    model.save!
    assert_equal "space",model.title
  end

  test "model with no contributor" do
    model=models(:model_with_no_contributor)
    assert_nil model.contributor
  end

  test "versions destroyed as dependent" do
    model=models(:teusink)
    User.current_user = model.contributor
    assert_equal 2,model.versions.size,"There should be 2 versions of this Model"
    assert_difference("Model.count",-1) do
      assert_difference("Model::Version.count",-2) do
        model.destroy
      end
    end
  end

  test "make sure content blob is preserved after deletion" do
    model = models(:teusink)
    User.current_user = model.contributor
    assert_not_nil model.content_blob,"Must have an associated content blob for this test to work"
    cb=model.content_blob
    assert_difference("Model.count",-1) do
      assert_no_difference("ContentBlob.count") do
        model.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    model = models(:teusink)
    User.current_user = model.contributor
    assert_difference("Model.count",-1) do
      model.destroy
    end
    assert_nil Model.find_by_id(model.id)
    assert_difference("Model.count",1) do
      disable_authorization_checks {Model.restore_trash!(model.id)}
    end
    assert_not_nil Model.find_by_id(model.id)
  end


  test 'failing to delete due to can_delete does not create trash' do
    model = Factory :model, :policy => Factory(:private_policy)
    assert_no_difference("Model.count") do
      model.destroy
    end
    assert_nil Model.restore_trash(model.id)
  end
  
  test "test uuid generated" do
    x = models(:teusink)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end

  test "uuid doesn't change" do
    x = models(:teusink)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
