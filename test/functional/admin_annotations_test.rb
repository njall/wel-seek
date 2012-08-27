require 'test_helper'

class AdminAnnotationsTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  tests AdminController

  test "editing tags visible to admin" do
    login_as(:quentin)
    get :tags
    assert_response :success

    p = Factory :person
    protocol = Factory :protocol, :policy => Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag,:annotatable=>protocol,:source=>p,:value=>"fish"
    get :edit_tag, :id=>fish.value.id
    assert_response :success
  end

  test "edit tag" do
    login_as(:quentin)
    p = Factory :person
    protocol = Factory :protocol, :policy => Factory(:all_sysmo_viewable_policy)
    fish=Factory :tag,:annotatable=>protocol,:source=>p,:value=>"fish"
    assert_equal ['fish'], protocol.annotations.select{|a|a.source==p}.collect{|a| a.value.text}

    golf = Factory :tag,:annotatable=>protocol,:source=>p,:value=>"golf"
    post :edit_tag, :id=>fish.value.id, :tags_autocompleter_selected_ids=>[golf.value.id], :tags_autocompleter_unrecognized_items=>["microbiology", "spanish"]
    assert_redirected_to :action=>:tags

    protocol.reload
    assert_equal ["golf","microbiology","spanish"],protocol.annotations.collect{|a| a.value.text}.uniq.sort
  end

  test "edit tag to itself" do
    login_as(:quentin)
    p = Factory :person
    protocol = Factory :protocol, :policy => Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag,:annotatable=>protocol,:source=>p,:value=>Factory(:text_value, :text => 'fish')
    assert_equal ['fish'], protocol.annotations.select{|a|a.source==p}.collect{|a| a.value.text}

    post :edit_tag, :id=>fish.value.id, :tags_autocompleter_selected_ids=>[fish.value.id]
    assert_redirected_to :action=>:tags

    protocol.reload
    assert_equal ['fish'], protocol.annotations.select{|a|a.source==p}.collect{|a| a.value.text}
  end

  test "editing tags blocked for non admin" do
    login_as(:aaron)
    get :tags
    assert_redirected_to :root
    assert_not_nil flash[:error]

    p = Factory :person
    protocol = Factory :protocol, :policy => Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag,:annotatable=>protocol,:source=>p,:value=>"fish"

    get :edit_tag, :id=>fish.value.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :edit_tag, :id=>fish.value.id, :tags_autocompleter_unrecognized_items=>["microbiology", "spanish"]
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :delete_tag, :id=>fish.value.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

  end

  test "edit tag to multiple" do
    login_as(:quentin)
    person=Factory :person
    person.tools= ["linux", "ruby", "fishing"]
    person.expertise=["fishing"]
    person.save!

    updated_at=person.updated_at

    assert_equal ["fishing", "linux", "ruby"], person.tools.collect{|t| t.text}.uniq.sort
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    sleep(2) #for timestamp test

    golf=Factory(:text_value, :text => 'golf')
    fishing=person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    post :edit_tag, :id=>fishing.value.id, :tags_autocompleter_selected_ids=>[golf.id], :tags_autocompleter_unrecognized_items=>["microbiology","spanish"]
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["golf", "linux", "microbiology", "ruby","spanish"]
    expected_expertise=["golf", "microbiology", "spanish"]

    person.reload
    assert_equal expected_tools, person.tools.collect{|t| t.text}.uniq.sort
    assert_equal expected_expertise, person.expertise.collect{|t| t.text}.uniq.sort

    assert_equal updated_at.to_s,person.updated_at.to_s,"timestamps were modified for taggable and shouldn't have been"

    assert person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.blank?
  end

  test "edit tag includes orginal" do
    login_as(:quentin)
    person=Factory :person
    person.tools= ["linux", "ruby", "fishing"]
    person.expertise=["fishing"]
    person.save!

    assert_equal ["fishing", "linux", "ruby"], person.tools.collect{|t| t.text}.uniq.sort
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    golf=Factory(:tag, :annotatable => person, :source => User.current_user , :value => 'golf')
    fishing=person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    post :edit_tag, :id=>fishing.value.id, :tags_autocompleter_selected_ids=>[golf.value.id], :tags_autocompleter_unrecognized_items=>["fishing","spanish"]
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["fishing", "golf", "linux", "ruby", "spanish"]
    expected_expertise=["fishing", "golf", "spanish"]

    person.reload
    assert_equal expected_tools, person.tools.collect{|t| t.text}.uniq.sort
    assert_equal expected_expertise, person.expertise.collect{|t| t.text}.uniq.sort

    assert !person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.blank?
  end

  test "edit tag to new tag" do
    login_as(:quentin)
    person=Factory :person
    person.tools= ["linux", "ruby", "fishing"]
    person.expertise=["fishing"]
    person.save!

    assert_equal ["fishing", "linux", "ruby"], person.tools.collect{|t| t.text}.uniq.sort
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    fishing= person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    assert person.annotations_with_attribute("expertise").select{|a| a.value.text == 'sparrow'}.blank?

    post :edit_tag, :id=>fishing.value.id, :tags_autocompleter_selected_ids=>[], :tags_autocompleter_unrecognized_items=>["sparrow"]
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["linux", "ruby", "sparrow"]
    expected_expertise=["sparrow"]

    person.reload
    assert_equal expected_tools, person.tools.collect{|t| t.text}.uniq.sort
    assert_equal expected_expertise, person.expertise.collect{|t| t.text}.uniq
  end

  test "edit tag to blank" do
    login_as(:quentin)
    person=Factory :person
    person.tools= ["linux", "ruby", "fishing"]
    person.expertise=["fishing"]
    person.save!

    assert_equal ["fishing", "linux", "ruby"], person.tools.collect{|t| t.text}.uniq.sort
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    fishing= person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    post :edit_tag, :id=>fishing.value.id, :tags_autocompleter_selected_ids=>[], :tags_autocompleter_unrecognized_items=>[""]
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["linux", "ruby"]
    expected_expertise=[]

    person.reload
    assert_equal expected_tools, person.tools.collect{|t| t.text}.uniq.sort
    assert_equal expected_expertise, person.expertise.collect{|t| t.text}

  end

  test "edit tag to existing tag" do
    login_as(:quentin)
    person=Factory :person
    person.tools= ["linux", "ruby", "fishing"]
    person.expertise=["fishing"]
    person.save!

    assert_equal ["fishing", "linux", "ruby"], person.tools.collect{|t| t.text}.uniq.sort
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    fishing= person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    golf=Factory(:tag, :annotatable => person, :source => users(:quentin), :value => 'golf')
    post :edit_tag, :id=>fishing.value.id, :tags_autocompleter_selected_ids=>[golf.value.id], :tags_autocompleter_unrecognized_items=>[""]
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    person=Person.find(person.id)
    expected_tools=["golf", "linux", "ruby"]
    expected_expertise=["golf"]

    person.reload
    assert_equal expected_tools, person.tools.collect{|t| t.text}.uniq.sort
    assert_equal expected_expertise, person.expertise.collect{|t| t.text}.uniq
  end

  test "delete_tag" do
    login_as(:quentin)

    person=Factory :person
    person.tools= ["fishing"]
    person.expertise=["fishing"]
    person.save!

    assert_equal ["fishing"], person.tools.collect{|t| t.text}.uniq
    assert_equal ["fishing"], person.expertise.collect{|t| t.text}.uniq

    fishing= person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    #must be a post
    get :delete_tag, :id=>fishing.value.id
    assert_redirected_to :action=>:tags
    assert_not_nil flash[:error]

    fishing=person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_not_nil fishing

    post :delete_tag, :id=>fishing.value.id
    assert_redirected_to :action=>:tags
    assert_nil flash[:error]

    fishing=person.annotations_with_attribute("expertise").select{|a| a.value.text == 'fishing'}.first
    assert_nil fishing

    person=Person.find(person.id)
    assert_equal [], person.tools
    assert_equal [], person.expertise
  end
end