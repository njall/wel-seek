require 'test_helper'

class ExperimentAssetTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    User.current_user = Factory :user
  end

  def teardown
    User.current_user = nil
  end

  test "create explicit version" do
    protocol = Factory :protocol, :contributor => User.current_user
    protocol.save_as_new_version
    experiment = Factory :experiment, :contributor => User.current_user.person

    version_number = protocol.version

    a = ExperimentAsset.new
    a.asset = protocol.latest_version
    a.experiment = experiment

    a.save!
    a.reload

    protocol.save_as_new_version

    assert_not_equal(protocol.latest_version, a.asset) #Check still linked to version made on create
    assert_equal(version_number,a.asset.version)
    assert_equal(protocol.find_version(version_number), a.asset)
    
    assert_equal(experiment, a.experiment)
  end   
  
  test "versioned asset" do
    protocol = Factory :protocol, :contributor => User.current_user
    protocol.save_as_new_version
    experiment = Factory :experiment, :contributor => User.current_user.person
    
    a = ExperimentAsset.new
    a.asset = protocol.latest_version
    a.experiment = experiment
    a.version=1
    a.save!
        
    assert_equal 1,a.versioned_asset.version
    assert_equal protocol.find_version(1),a.versioned_asset
    
    a = ExperimentAsset.new
    a.asset = protocol.latest_version
    a.experiment = experiment
    a.save!
    
    assert_equal protocol.version,a.versioned_asset.version
    assert_equal protocol.latest_version,a.versioned_asset
  end
  
end
