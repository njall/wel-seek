require 'test_helper'

class ProtocolTest < ActiveSupport::TestCase
  fixtures :all
  
  test "project" do
    s=protocols(:editable_protocol)
    p=projects(:sysmo_project)
    assert_equal p,s.projects.first
  end

  test "sort by updated_at" do
    last = 9999999999999 #safe until the year 318857 !

    Protocol.record_timestamps = false
    Factory(:protocol,:title=>"8 day old Protocol",:updated_at=>8.day.ago)
    Factory(:protocol,:title=>"20 day old Protocol",:updated_at=>20.days.ago)
    Protocol.record_timestamps = true
    
    protocols = Protocol.find(:all)

    protocols.each do |protocol|
      assert protocol.updated_at.to_i <= last
      last=protocol.updated_at.to_i
    end
  end

  def test_title_trimmed 
    protocol=Factory(:protocol, :title => " test protocol")
    assert_equal("test protocol",protocol.title)
  end

  test "validation" do
    asset=Protocol.new :title=>"fred",:projects=>[projects(:sysmo_project)]
    assert asset.valid?

    asset=Protocol.new :projects=>[projects(:sysmo_project)]
    assert !asset.valid?

    asset=Protocol.new :title=>"fred"
    assert !asset.valid?
  end

  test "experiment association" do
    protocol = protocols(:protocol_with_fully_public_policy)
    experiment = experiments(:modelling_experiment_with_data_and_relationship)
    experiment_asset = experiment_assets(:metabolomics_experiment_asset1)
    assert_not_equal experiment_asset.asset, protocol
    assert_not_equal experiment_asset.experiment, experiment
    experiment_asset.asset = protocol
    experiment_asset.experiment = experiment
    User.with_current_user(experiment.contributor.user){experiment_asset.save!}
    experiment_asset.reload
    assert experiment_asset.valid?
    assert_equal experiment_asset.asset, protocol
    assert_equal experiment_asset.experiment, experiment

  end

  def test_avatar_key
    assert_nil protocols(:editable_protocol).avatar_key
    assert protocols(:editable_protocol).use_mime_type_for_avatar?

    assert_nil protocol_versions(:my_first_protocol_v1).avatar_key
    assert protocol_versions(:my_first_protocol_v1).use_mime_type_for_avatar?
  end
  
  def test_defaults_to_private_policy
    protocol=Protocol.new Factory.attributes_for(:protocol).tap{|h|h[:policy] = nil}
    protocol.save!
    protocol.reload
    assert_not_nil protocol.policy
    assert_equal Policy::PRIVATE, protocol.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, protocol.policy.access_type
    assert_equal false,protocol.policy.use_whitelist
    assert_equal false,protocol.policy.use_blacklist
    assert protocol.policy.permissions.empty?
  end

  def test_version_created_for_new_protocol

    protocol=Factory(:protocol)

    assert protocol.save

    protocol=Protocol.find(protocol.id)

    assert 1,protocol.version
    assert 1,protocol.versions.size
    assert_equal protocol,protocol.versions.last.protocol
    assert_equal protocol.title,protocol.versions.first.title

  end

  #really just to test the fixtures for versions, but may as well leave here.
  def test_version_from_fixtures
    protocol_version=protocol_versions(:my_first_protocol_v1)
    assert_equal 1,protocol_version.version
    assert_equal users(:owner_of_my_first_protocol),protocol_version.contributor
    assert_equal content_blobs(:content_blob_with_little_file),protocol_version.content_blob

    protocol=protocols(:my_first_protocol)
    assert_equal protocol.id,protocol_version.protocol_id

    assert_equal 1,protocol.version
    assert_equal protocol.title,protocol.versions.first.title

  end  

  def test_create_new_version
    protocol=protocols(:my_first_protocol)
    User.current_user = protocol.contributor
    protocol.save!
    protocol=Protocol.find(protocol.id)
    assert_equal 1,protocol.version
    assert_equal 1,protocol.versions.size
    assert_equal "My First Favourite Protocol",protocol.title

    protocol.save!
    protocol=Protocol.find(protocol.id)

    assert_equal 1,protocol.version
    assert_equal 1,protocol.versions.size
    assert_equal "My First Favourite Protocol",protocol.title

    protocol.title="Updated Protocol"

    protocol.save_as_new_version("Updated protocol as part of a test")
    protocol=Protocol.find(protocol.id)
    assert_equal 2,protocol.version
    assert_equal 2,protocol.versions.size
    assert_equal "Updated Protocol",protocol.title
    assert_equal "Updated Protocol",protocol.versions.last.title
    assert_equal "Updated protocol as part of a test",protocol.versions.last.revision_comments
    assert_equal "My First Favourite Protocol",protocol.versions.first.title

    assert_equal "My First Favourite Protocol",protocol.find_version(1).title
    assert_equal "Updated Protocol",protocol.find_version(2).title

  end

  def test_project_for_protocol_and_protocol_version_match
    protocol=protocols(:my_first_protocol)
    project=projects(:sysmo_project)
    assert_equal project,protocol.projects.first
    assert_equal project,protocol.latest_version.projects.first
  end

  test "protocol with no contributor" do
    protocol=protocols(:protocol_with_no_contributor)
    assert_nil protocol.contributor
  end

  test "versions destroyed as dependent" do
    protocol = protocols(:my_first_protocol)
    assert_equal 1,protocol.versions.size,"There should be 1 version of this Protocol"
    assert_difference(["Protocol.count","Protocol::Version.count"],-1) do
      User.current_user = protocol.contributor
      protocol.destroy
    end    
  end

  test "make sure content blob is preserved after deletion" do
    protocol = protocols(:my_first_protocol)
    assert_not_nil protocol.content_blob,"Must have an associated content blob for this test to work"
    cb=protocol.content_blob
    assert_difference("Protocol.count",-1) do
      assert_no_difference("ContentBlob.count") do
        User.current_user = protocol.contributor
        protocol.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    protocol = protocols(:my_first_protocol)
    User.current_user = protocol.contributor
    assert_difference("Protocol.count",-1) do
      protocol.destroy
    end
    assert_nil Protocol.find_by_id(protocol.id)
    assert_difference("Protocol.count",1) do
      disable_authorization_checks {Protocol.restore_trash!(protocol.id)}
    end
    assert_not_nil Protocol.find_by_id(protocol.id)
  end

  test 'failing to delete due to can_delete does not create trash' do
    protocol = Factory :protocol, :policy => Factory(:private_policy)
    assert_no_difference("Protocol.count") do
      protocol.destroy
    end
    assert_nil Protocol.restore_trash(protocol.id)
  end

  test "test uuid generated" do
    x = protocols(:my_first_protocol)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end
  
  test "uuid doesn't change" do
    x = protocols(:my_first_protocol)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test "contributing_user" do
    protocol = Factory :protocol
    assert protocol.contributor
    assert_equal protocol.contributor, protocol.contributing_user
    protocol_without_contributor = Factory :protocol, :contributor => nil
    assert_equal nil, protocol_without_contributor.contributing_user
  end
end
