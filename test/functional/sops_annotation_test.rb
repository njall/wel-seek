require 'test_helper'

class ProtocolsAnnotationTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  fixtures :all

  tests ProtocolsController

  test "update tags with ajax only applied when viewable" do
    p=Factory :person
    p2=Factory :person
    viewable_protocol=Factory :protocol,:contributor=>p2,:policy=>Factory(:publicly_viewable_policy)
    dummy_protocol=Factory :protocol

    login_as p.user

    assert viewable_protocol.can_view?(p.user)
    assert !viewable_protocol.can_edit?(p.user)

    golf=Factory :tag,:annotatable=>dummy_protocol,:source=>p2,:value=>"golf"

    xml_http_request :post, :update_annotations_ajax,{:id=>viewable_protocol,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    viewable_protocol.reload

    assert_equal ["golf"],viewable_protocol.annotations.collect{|a| a.value.text}

    private_protocol=Factory :protocol,:contributor=>p2,:policy=>Factory(:private_policy)

    assert !private_protocol.can_view?(p.user)
    assert !private_protocol.can_edit?(p.user)

    xml_http_request :post, :update_annotations_ajax,{:id=>private_protocol,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    private_protocol.reload
    assert private_protocol.annotations.empty?

  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    protocol = Factory :protocol,:contributor=>p.user


    assert protocol.annotations.empty?,"this protocol should have no tags for the test"

    golf = Factory :tag,:annotatable=>protocol,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>protocol,:source=>p2.user,:value=>"sparrow"

    protocol.reload

    assert_equal ["golf","sparrow"],protocol.annotations.collect{|a| a.value.text}.sort
    assert_equal [],protocol.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>protocol,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id]}

    protocol.reload

    assert_equal ["golf","soup","sparrow"],protocol.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],protocol.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "should update protocol tags" do
    p = Factory :person
    protocol=Factory :protocol,:contributor=>p
    dummy_protocol = Factory :protocol

    login_as p.user
    assert protocol.annotations.empty?,"Should have no annotations"
    Factory :tag,:source=>p.user,:annotatable=>protocol,:value=>"fish"
    Factory :tag,:source=>p.user,:annotatable=>protocol,:value=>"apple"
    golf = Factory :tag, :source=>p.user, :annotatable=>dummy_protocol, :value=>"golf"

    protocol.reload
    assert_equal ["apple","fish"],protocol.annotations.collect{|a| a.value.text}.sort

    put :update, :id => protocol, :tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id],:protocol=>{}, :sharing=>valid_sharing
    protocol.reload

    assert_equal ["golf","soup"],protocol.annotations.collect{|a| a.value.text}.sort
  end

  test "should update protocol tags with correct ownership" do
    p1=Factory :person
    p2=Factory :person
    p3=Factory :person

    protocol = Factory :protocol,:contributor=>p1

    assert protocol.annotations.empty?, "This protocol should have no tags"

    login_as p1.user

    Factory :tag,:source=>p1.user,:annotatable=>protocol,:value=>"fish"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"fish"
    golf = Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"golf"
    Factory :tag,:source=>p3.user,:annotatable=>protocol,:value=>"apple"

    protocol.reload

    assert_equal ["fish"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}
    assert_equal ["fish","golf"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort
    assert_equal ["apple"],protocol.annotations.select{|a|a.source==p3.user}.collect{|a| a.value.text}
    assert_equal ["apple","fish","golf"],protocol.annotations.collect{|a| a.value.text}.uniq.sort

    put :update, :id => protocol, :tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id],:protocol=>{}, :sharing=>valid_sharing
    protocol.reload

    assert_equal ["soup"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}
    assert_equal ["golf"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort
    assert_equal [],protocol.annotations.select{|a|a.source==p3.user}.collect{|a| a.value.text}
    assert_equal ["golf","soup"],protocol.annotations.collect{|a| a.value.text}.uniq.sort

  end

  test "should update protocol tags with correct ownership2" do
    #a specific case where a tag to keep was added by both the owner and another user.
    #Test checks that the correct tag ownership is preserved.

    p1=Factory :person
    p2=Factory :person

    protocol = Factory :protocol,:contributor=>p1

    assert protocol.annotations.empty?, "This protocol should have no tags"

    login_as p1.user

    Factory :tag,:source=>p1.user,:annotatable=>protocol,:value=>"fish"
    golf = Factory :tag,:source=>p1.user,:annotatable=>protocol,:value=>"golf"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"apple"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"golf"

    protocol.reload

    assert_equal ["fish","golf"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["apple","golf"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    put :update, :id => protocol, :tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id],:protocol=>{}, :sharing=>valid_sharing
    protocol.reload

    assert_equal ["golf"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "update tags with known tags passed as unrecognised" do
    #checks that when a known tag is incorrectly passed as a new tag, it is correctly handled
    #this can happen when a tag is typed in full, rather than relying on autocomplete, and can affect the correct preservation of ownership

    p1=Factory :person
    p2=Factory :person

    protocol = Factory :protocol,:contributor=>p1

    assert protocol.annotations.empty?, "This protocol should have no tags"

    login_as p1.user

    fish = Factory :tag,:source=>p1.user,:annotatable=>protocol,:value=>"fish"
    golf = Factory :tag,:source=>p1.user,:annotatable=>protocol,:value=>"golf"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"fish"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>"soup"

    protocol.reload

    assert_equal ["fish","golf"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["fish","soup"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    put :update, :id => protocol, :tag_autocompleter_unrecognized_items=>["fish"],:tag_autocompleter_selected_ids=>[golf.value.id],:protocol=>{}, :sharing=>valid_sharing

    protocol.reload

    assert_equal ["fish","golf"],protocol.annotations.select{|a|a.source==p1.user}.collect{|a| a.value.text}.sort
    assert_equal ["fish"],protocol.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "create protocol with tags" do
    p = Factory :person
    login_as p.user

    another_protocol = Factory :protocol,:contributor=>p.user
    golf = Factory :tag,:source=>p.user,:annotatable=>another_protocol,:value=>"golf"

    protocol={:title=>"Test", :data=>fixture_file_upload('files/file_picture.png'),:projects=>[p.projects.first]}

    assert_difference("Protocol.count") do
      put :create,:protocol=>protocol,:sharing=>valid_sharing,:tag_autocompleter_unrecognized_items=>["fish"],:tag_autocompleter_selected_ids=>[golf.value.id]
    end

    assert_redirected_to protocol_path(assigns(:protocol))
    protocol=assigns(:protocol)
    assert_equal ["fish","golf"],protocol.tags_as_text_array.sort
  end

  test "tag cloud shown on show page" do
    p=Factory :person
    login_as p.user
    protocol = Factory :protocol,:contributor=>p.user

    get :show,:id=>protocol
    assert_response :success

    assert_select "div#tags_box" do
      assert_select "a",:text=>/Add your tags/,:count=>1
      assert_select "a",:text=>/Update your tags/,:count=>0
    end

    assert_select "div#tag_cloud" do
      assert_select "p",:text=>/not yet been tagged/,:count=>1
    end

    protocol.tag_with ["fish","sparrow","sprocket"]

    get :show,:id=>protocol
    assert_response :success

    assert_select "div#tags_box" do
      assert_select "a",:text=>/Add your tags/,:count=>0
      assert_select "a",:text=>/Update your tags/,:count=>1
    end

    assert_select "div#tag_cloud" do
      assert_select "a",:text=>"fish",:count=>1
      assert_select "a",:text=>"sparrow",:count=>1
      assert_select "a",:text=>"sprocket",:count=>1
    end
  end

  test "asset tag cloud shouldn't duplicate tags for different owners" do
    p=Factory :person
    p2=Factory :person
    login_as p.user
    protocol = Factory :protocol,:contributor=>p.user
    
    coffee = Factory :tag,:source=>p.user,:annotatable=>protocol,:value=>"coffee"
    Factory :tag,:source=>p2.user,:annotatable=>protocol,:value=>coffee.value

    get :show,:id=>protocol
    assert_response :success

    assert_select "div#tag_cloud" do
      assert_select "a",:text=>/coffee/,:count=>1
    end

  end

  test "form includes tag section" do
    p=Factory :person
    login_as p.user
    get :new
    assert_response :success
    assert_select "input#tag_autocomplete_input"

    protocol=Factory :protocol,:contributor=>p.user
    get :edit,:id=>protocol
    assert_response :success
    assert_select "input#tag_autocomplete_input"
  end

end