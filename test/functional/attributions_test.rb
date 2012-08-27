require 'test_helper'

class AttributionsTest < ActionController::TestCase
  # use ProtocolsController, because attributions don't have their own controller
  tests ProtocolsController
  
  fixtures :all
  
  
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  def setup
    login_as(:owner_of_my_first_protocol)
  end
  
  
  def test_should_create_attribution_when_creating_new_protocol
    # create a Protocol and verify that both Protocol and attribution get created
    assert !users(:owner_of_my_first_protocol).person.projects.empty?
    assert users(:owner_of_my_first_protocol).person.projects.include?(projects(:myexperiment_project))
    assert_difference ['Protocol.count', 'Relationship.count'] do
      post :create, :protocol => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 1]])
    end
    assert_redirected_to protocol_path(assigns(:protocol))
  end
  
  
  def test_shouldnt_create_duplicated_attribution
    # create a Protocol and verify that both Protocol and attribution get created
    # (two identical attributions will be posted, but only one needs to be created)
    assert_difference ['Protocol.count', 'Relationship.count'] do
      post :create, :protocol => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 1], ["Protocol", 1]])
    end
    assert_redirected_to protocol_path(assigns(:protocol))
  end
  
  
  def test_should_remove_attribution_on_update
    # create a Protocol / attribution first
    assert_difference ['Protocol.count', 'Relationship.count'] do
      post :create, :protocol => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 1]])
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    
    # update the Protocol, but supply no data about attributions - these should be removed
    assert_no_difference('Protocol.count') do
      assert_difference('Relationship.count', -1) do
        put :update, :id => assigns(:protocol).id, :protocol => {:title => "edited_title",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing,:attributions=>nil # NB! no attributions supplied - should remove if any existed for the protocol
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
  end
  
  
  def test_attributions_will_get_destroyed_when_master_protocol_is_destroyed
    # create a Protocol and verify that both Protocol and attributions get created
    assert_difference('Protocol.count') do
      assert_difference('Relationship.count', +2) do
        post :create, :protocol => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 111], ["Protocol", 222]])
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    
    # destroy the new protocol and verify that the attributions get destroyed too
    protocol_instance = Protocol.find(assigns(:protocol).id)
    assert_difference('Protocol.count', -1) do
      assert_difference('Relationship.count', -2) do
        User.current_user = protocol_instance.contributor
        protocol_instance.destroy
      end
    end
    
    # double-check to see that no attributions for this protocol remain
    destroyed_protocol_attributions = Relationship.find(:all, :conditions => { :subject_id => protocol_instance.id,
                                                                          :subject_type => protocol_instance.class.name,
                                                                          :predicate => Relationship::ATTRIBUTED_TO })
    assert_equal [], destroyed_protocol_attributions
  end
  
  
  def test_attributions_are_getting_properly_synchronized
    # create a Protocol / attributions first
    assert_difference('Protocol.count') do
      assert_difference('Relationship.count', +2) do
        post :create, :protocol => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions",:projects=>[projects(:myexperiment_project)]}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 1], ["Protocol", 2]])
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
  
    # store IDs of created attribution for further checks
    protocol_id = assigns(:protocol).id
    protocol_instance = Protocol.find(protocol_id)
    
    assert_equal 2, protocol_instance.attributions.length
    if protocol_instance.attributions[0].object_id == 1
      attr_to_protocol_one = protocol_instance.attributions[0]
      attr_to_protocol_two = protocol_instance.attributions[1]
    else
      attr_to_protocol_one = protocol_instance.attributions[1]
      attr_to_protocol_two = protocol_instance.attributions[0]
    end
    
    # update the Protocol: attributions data will add a new attribution, remove one old and keep one old unchanged -
    # this leaves the total number of attributions unchaged
    assert_no_difference ['Protocol.count', 'Relationship.count'] do
      put :update, :id => assigns(:protocol).id, :protocol => {:title => "edited_title"}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Protocol", 44], ["Protocol", 2]])
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    
    # verify it's still the same Protocol
    assert_equal protocol_id, assigns(:protocol).id
    
    
    # --- Verify that synchronisation was performed correctly ---
    
    # attribution that was supposed to be deleted was really destroyed
    deleted_attr_to_protocol_one = Relationship.find(:first, :conditions => { :subject_id => attr_to_protocol_one.subject_id, :subject_type => attr_to_protocol_one.subject_type,
                                                                         :predicate => attr_to_protocol_one.predicate, :object_id => attr_to_protocol_one.object_id,
                                                                         :object_type => attr_to_protocol_one.object_type } )
    assert_equal nil, deleted_attr_to_protocol_one
    
    
    # attribution that was supposed to stay unchanged should preserve its ID -
    # this will then indicate that it was identified to be existing and was properly
    # handled by keeping intact instead of removing and re-creating new record with the
    # same attribution data
    remaining_attr_to_protocol_two = Relationship.find(:first, :conditions => { :subject_id => attr_to_protocol_two.subject_id, :subject_type => attr_to_protocol_two.subject_type,
                                                                           :predicate => attr_to_protocol_two.predicate, :object_id => attr_to_protocol_two.object_id,
                                                                           :object_type => attr_to_protocol_two.object_type } )
    assert_equal attr_to_protocol_two.id, remaining_attr_to_protocol_two.id
    
    
    # make sure that new attribution was created correctly
    # (we have already checked that the total number of attributions after running the test
    #  is correct - one removed, one added, one left unchanged: total - unchanged)
    new_attr = Relationship.find(:first, :conditions => { :subject_id => protocol_id, :subject_type => protocol_instance.class.name,
                                                          :predicate => Relationship::ATTRIBUTED_TO, :object_id => 44,
                                                          :object_type => "Protocol" } )
    assert (!new_attr.nil?), "new attribution should't be nil - nil means that it wasn't created"
  end

end