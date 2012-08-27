require 'test_helper'

class ProtocolsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper

  def setup
    login_as(:quentin)
    @object=protocols(:downloadable_protocol)
  end

  def test_get_xml_specific_version
    login_as(:owner_of_my_first_protocol)
    get :show, :id=>protocols(:downloadable_protocol), :version=>2, :format=>"xml"
    perform_api_checks
    xml          =@response.body
    document     = LibXML::XML::Document.string(xml)
    version_node = document.find_first("//ns:version", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil version_node
    assert_equal "2", version_node.content
    content_blob_node = document.find_first("//ns:blob", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil content_blob_node
    md5sum=content_blob_node.find_first("//ns:md5sum", "ns:http://www.sysmo-db.org/2010/xml/rest").content

    #now check version 1
    get :show, :id=>protocols(:downloadable_protocol), :version=>1, :format=>"xml"
    perform_api_checks
    xml          =@response.body
    document     = LibXML::XML::Document.string(xml)
    version_node = document.find_first("//ns:version", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil version_node
    assert_equal "1", version_node.content
    content_blob_node = document.find_first("//ns:blob", "ns:http://www.sysmo-db.org/2010/xml/rest")
    assert_not_nil content_blob_node
    md5sum2=content_blob_node.find_first("//ns:md5sum", "ns:http://www.sysmo-db.org/2010/xml/rest").content
    assert_not_equal md5sum, md5sum2

  end

  test 'creators show in list item' do
    p1=Factory :person
    p2=Factory :person
    protocol=Factory(:protocol,:title=>"ZZZZZ",:creators=>[p2],:contributor=>p1.user,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))

    get :index,:page=>"Z"

    #check the test is behaving as expected:
    assert_equal p1.user,protocol.contributor
    assert protocol.creators.include?(p2)
    assert_select ".list_item_title a[href=?]",protocol_path(protocol),"ZZZZZ","the data file for this test should appear as a list item"

    #check for avatars
    assert_select ".list_item_avatar" do
      assert_select "a[href=?]",person_path(p2) do
        assert_select "img"
      end
      assert_select "a[href=?]",person_path(p1) do
        assert_select "img"
      end
    end
  end

  test "request file button visibility when logged in and out" do

    protocol = Factory :protocol,:policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)

    assert !protocol.can_download?, "The Protocol must not be downloadable for this test to succeed"

    get :show, :id => protocol
    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request Protocol/,:count=>1

    logout
    get :show, :id => protocol
    assert_response :success
    assert_select "#request_resource_button > a",:text=>/Request Protocol/,:count=>0
  end

  test "fail gracefullly when trying to access a missing protocol" do
    get :show,:id=>99999
    assert_redirected_to protocols_path
    assert_not_nil flash[:error]
  end

  test "should not create protocol with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url ="file://"+file_path
    uri      =URI.parse(file_url)

    assert_no_difference('Protocol.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :protocol => {:title=>"Test", :data_url=>uri.to_s}, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash[:error]
  end

  def test_title
    get :index
    assert_select "title", :text=>/The Sysmo SEEK Protocols.*/, :count=>1
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:protocols)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:protocols).sort_by(&:id), Authorization.authorize_collection("view", assigns(:protocols), users(:aaron)).sort_by(&:id), "protocols haven't been authorized properly"
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select "h1", :text=>"New Protocol"
  end

  test "should correctly handle bad data url" do
    protocol={:title=>"Test", :data_url=>"http:/sdfsdfds.com/sdf.png",:projects=>[projects(:sysmo_project)]}
    assert_no_difference('Protocol.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :protocol => protocol, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]

    #not even a valid url
    protocol={:title=>"Test", :data_url=>"s  df::sd:dfds.com/sdf.png",:projects=>[projects(:sysmo_project)]}
    assert_no_difference('Protocol.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :protocol => protocol, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end

  test "should not create invalid protocol" do
    protocol={:title=>"Test",:projects=>[projects(:sysmo_project)]}
    assert_no_difference('Protocol.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :protocol => protocol, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end

  test "associates experiment" do
    login_as(:owner_of_my_first_protocol) #can edit experiment_can_edit_by_my_first_protocol_owner
    s = protocols(:my_first_protocol)
    original_experiment = experiments(:experiment_can_edit_by_my_first_protocol_owner1)
    asset_ids = original_experiment.related_asset_ids 'Protocol'
    assert asset_ids.include? s.id

    new_experiment=experiments(:experiment_can_edit_by_my_first_protocol_owner2)
    new_asset_ids = new_experiment.related_asset_ids 'Protocol'
    assert !new_asset_ids.include?(s.id)

    put :update, :id => s.id, :protocol =>{}, :experiment_ids=>[new_experiment.id.to_s]

    assert_redirected_to protocol_path(s)

    s.reload
    original_experiment.reload
    new_experiment.reload

    assert !original_experiment.related_asset_ids('Protocol').include?(s.id)
    assert new_experiment.related_asset_ids('Protocol').include?(s.id)
  end

  test "should create protocol" do
    login_as(:owner_of_my_first_protocol) #can edit experiment_can_edit_by_my_first_protocol_owner
    experiment=experiments(:experiment_can_edit_by_my_first_protocol_owner1)
    assert_difference('Protocol.count') do
      assert_difference('ContentBlob.count') do
        post :create, :protocol => valid_protocol, :sharing=>valid_sharing, :experiment_ids => [experiment.id.to_s]
      end
    end

    assert_redirected_to protocol_path(assigns(:protocol))
    assert_equal users(:owner_of_my_first_protocol), assigns(:protocol).contributor

    assert assigns(:protocol).content_blob.url.blank?
    assert !assigns(:protocol).content_blob.data_io_object.read.nil?
    assert assigns(:protocol).content_blob.file_exists?
    assert_equal "file_picture.png", assigns(:protocol).original_filename
    experiment.reload
    assert experiment.related_asset_ids('Protocol').include? assigns(:protocol).id
  end

  def test_missing_sharing_should_default_to_private
    assert_difference('Protocol.count') do
      assert_difference('ContentBlob.count') do
        post :create, :protocol => valid_protocol
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    assert_equal users(:quentin), assigns(:protocol).contributor
    assert assigns(:protocol)

    protocol            =assigns(:protocol)
    private_policy = policies(:private_policy_for_asset_of_my_first_protocol)
    assert_equal private_policy.sharing_scope, protocol.policy.sharing_scope
    assert_equal private_policy.access_type, protocol.policy.access_type
    assert_equal private_policy.use_whitelist, protocol.policy.use_whitelist
    assert_equal private_policy.use_blacklist, protocol.policy.use_blacklist
    assert protocol.policy.permissions.empty?

    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success
  end

  test "should create protocol with url" do
    assert_difference('Protocol.count') do
      assert_difference('ContentBlob.count') do
        post :create, :protocol => valid_protocol_with_url, :sharing=>valid_sharing
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    assert_equal users(:quentin), assigns(:protocol).contributor
    assert !assigns(:protocol).content_blob.url.blank?
    assert assigns(:protocol).content_blob.data_io_object.nil?
    assert !assigns(:protocol).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:protocol).original_filename
    assert_equal "image/png", assigns(:protocol).content_type
  end

  test "should create protocol and store with url and store flag" do
    protocol_details             =valid_protocol_with_url
    protocol_details[:local_copy]="1"
    assert_difference('Protocol.count') do
      assert_difference('ContentBlob.count') do
        post :create, :protocol => protocol_details, :sharing=>valid_sharing
      end
    end
    assert_redirected_to protocol_path(assigns(:protocol))
    assert_equal users(:quentin), assigns(:protocol).contributor
    assert !assigns(:protocol).content_blob.url.blank?
    assert !assigns(:protocol).content_blob.data_io_object.read.nil?
    assert assigns(:protocol).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:protocol).original_filename
    assert_equal "image/png", assigns(:protocol).content_type
  end

  test "should show protocol" do
    login_as(:owner_of_my_first_protocol)
    s=protocols(:my_first_protocol)
    get :show, :id => s.id
    assert_response :success
  end

  test "should get edit" do
    login_as(:owner_of_my_first_protocol)
    get :edit, :id => protocols(:my_first_protocol)
    assert_response :success
    assert_select "h1", :text=>/Editing Protocol/

    #this is to check the Protocol is all upper case in the sharing form
    assert_select "label",:text=>/Keep this Protocol private/
  end

  

  test "publications excluded in form for protocols" do
    login_as(:owner_of_my_first_protocol)
    get :edit, :id => protocols(:my_first_protocol)
    assert_response :success
    assert_select "div#publications_fold_content", false

    get :new
    assert_response :success
    assert_select "div#publications_fold_content", false
  end

  test "should update protocol" do
    login_as(:owner_of_my_first_protocol)
    put :update, :id => protocols(:my_first_protocol).id, :protocol => {:title=>"Test2"}, :sharing=>valid_sharing
    assert_redirected_to protocol_path(assigns(:protocol))
  end


  test "should destroy protocol" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('Protocol.count', -1) do
      assert_no_difference("ContentBlob.count") do
        delete :destroy, :id => protocols(:my_first_protocol)
      end

    end
    assert_redirected_to protocols_path
  end


  test "should not be able to edit exp conditions for downloadable only protocol" do
    s=protocols(:downloadable_protocol)

    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>0
  end

  def test_should_be_able_to_edit_exp_conditions_for_owners_downloadable_only_protocol
    login_as(:owner_of_my_first_protocol)
    s=protocols(:downloadable_protocol)

    get :show, :id=>s
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_be_able_to_edit_exp_conditions_for_editable_protocol
    s=protocols(:editable_protocol)

    get :show, :id=>protocols(:editable_protocol)
    assert_select "a", :text=>/Edit experimental conditions/, :count=>1
  end

  def test_should_show_version
    s              =protocols(:editable_protocol)
    old_desc       =s.description
    old_desc_regexp=Regexp.new(old_desc)

    #create new version
    s.description  ="This is now version 2"
    assert s.save_as_new_version
    s=Protocol.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal 1, s.versions[0].version
    assert_equal 2, s.versions[1].version

    get :show, :id=>protocols(:editable_protocol)
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0

    get :show, :id=>protocols(:editable_protocol), :version=>"2"
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0

    get :show, :id=>protocols(:editable_protocol), :version=>"1"
    assert_select "p", :text=>/This is now version 2/, :count=>0
    assert_select "p", :text=>old_desc_regexp, :count=>1

  end

  def test_should_create_new_version
    s=protocols(:editable_protocol)

    assert_difference("Protocol::Version.count", 1) do
      post :new_version, :id=>s, :protocol=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision"
    end

    assert_redirected_to protocol_path(s)
    assert assigns(:protocol)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    s=Protocol.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal "file_picture.png", s.original_filename
    assert_equal "file_picture.png", s.versions[1].original_filename
    assert_equal "little_file.txt", s.versions[0].original_filename
    assert_equal "This is a new revision", s.versions[1].revision_comments

  end

  def test_should_not_create_new_version_for_downloadable_only_protocol
    s                    =protocols(:downloadable_protocol)
    current_version      =s.version
    current_version_count=s.versions.size

    assert_no_difference("Protocol::Version.count") do
      post :new_version, :id=>s, :data=>fixture_file_upload('files/file_picture.png'), :revision_comment=>"This is a new revision"
    end

    assert_redirected_to protocol_path(s)
    assert_not_nil flash[:error]

    s=Protocol.find(s.id)
    assert_equal current_version_count, s.versions.size
    assert_equal current_version, s.version

  end

  def test_should_duplicate_conditions_for_new_version
    s=protocols(:editable_protocol)
    condition1 = ExperimentalCondition.create(:unit        => units(:gram), :measured_item => measured_items(:weight),
                                              :start_value => 1, :protocol_id => s.id, :protocol_version => s.version)
    assert_difference("Protocol::Version.count", 1) do
      post :new_version, :id=>s, :protocol=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
    end

    assert_not_equal 0, s.find_version(1).experimental_conditions.count
    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_not_equal s.find_version(1).experimental_conditions, s.find_version(2).experimental_conditions
  end

  def test_adding_new_conditions_to_different_versions
    s =protocols(:editable_protocol)
    condition1 = ExperimentalCondition.create(:unit => units(:gram), :measured_item => measured_items(:weight),
                                              :start_value => 1, :protocol_id => s.id, :protocol_version => s.version)
    assert_difference("Protocol::Version.count", 1) do
      post :new_version, :id=>s, :protocol=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision" #v2
    end

    s.find_version(2).experimental_conditions.each { |e| e.destroy }
    assert_equal condition1, s.find_version(1).experimental_conditions.first
    assert_equal 0, s.find_version(2).experimental_conditions.count

    condition2 = ExperimentalCondition.create(:unit => units(:gram), :measured_item => measured_items(:weight),
                                              :start_value => 2, :protocol_id => s.id, :protocol_version => 2)

    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_equal condition2, s.find_version(2).experimental_conditions.first
    assert_not_equal condition2, s.find_version(1).experimental_conditions.first
    assert_equal condition1, s.find_version(1).experimental_conditions.first
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> protocols(:protocol_with_links_in_description)
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  def test_can_display_protocol_with_no_contributor
    get :show, :id=>protocols(:protocol_with_no_contributor)
    assert_response :success
  end

  def test_can_show_edit_for_protocol_with_no_contributor
    get :edit, :id=>protocols(:protocol_with_no_contributor)
    assert_response :success
  end

  def test_editing_doesnt_change_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this protocol
    protocol=protocols(:protocol_with_no_contributor)
    put :update, :id => protocol, :protocol => {:title=>"blah blah blah"}, :sharing=>valid_sharing
    updated_protocol=assigns(:protocol)
    assert_redirected_to protocol_path(updated_protocol)
    assert_equal "blah blah blah", updated_protocol.title, "Title should have been updated"
    assert_nil updated_protocol.contributor, "contributor should still be nil"
  end

  test "filtering by experiment" do
    experiment=experiments(:metabolomics_experiment)
    get :index, :filter => {:experiment => experiment.id}
    assert_response :success
  end

  test "filtering by study" do
    study=studies(:metabolomics_study)
    get :index, :filter => {:study => study.id}
    assert_response :success
  end

  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test "filtering by person" do
    login_as(:owner_of_my_first_protocol)
    person = people(:person_for_owner_of_my_first_protocol)
    p      =projects(:sysmo_project)
    get :index, :filter=>{:person=>person.id}, :page=>"all"
    assert_response :success
    protocol  = protocols(:downloadable_protocol)
    protocol2 = protocols(:protocol_with_fully_public_policy)
    assert_select "div.list_items_container" do
      assert_select "a", :text=>protocol.title, :count=>1
      assert_select "a", :text=>protocol2.title, :count=>0
    end
  end

  test "should not be able to update sharing without manage rights" do
    login_as(:quentin)
    user = users(:quentin)
    protocol   = protocols(:protocol_with_all_sysmo_users_policy)

    assert protocol.can_edit?(user), "protocol should be editable but not manageable for this test"
    assert !protocol.can_manage?(user), "protocol should be editable but not manageable for this test"
    assert_equal Policy::EDITING, protocol.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => protocol, :protocol => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to protocol_path(protocol)
    protocol.reload

    assert_equal "new title", protocol.title
    assert_equal Policy::EDITING, protocol.policy.access_type, "policy should not have been updated"

  end

  test "owner should be able to update sharing" do
    login_as(:owner_of_editing_for_all_sysmo_users_policy)
    user = users(:owner_of_editing_for_all_sysmo_users_policy)
    protocol   = protocols(:protocol_with_all_sysmo_users_policy)

    assert protocol.can_edit?(user), "protocol should be editable and manageable for this test"
    assert protocol.can_manage?(user), "protocol should be editable and manageable for this test"
    assert_equal Policy::EDITING, protocol.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => protocol, :protocol => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to protocol_path(protocol)
    protocol.reload

    assert_equal "new title", protocol.title
    assert_equal Policy::NO_ACCESS, protocol.policy.access_type, "policy should have been updated"
  end

  test "do publish" do
    login_as(:owner_of_my_first_protocol)
    protocol=protocols(:protocol_with_project_without_gatekeeper)
    assert protocol.can_manage?,"The protocol must be manageable for this test to succeed"
    post :publish,:id=>protocol
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "do not publish if not can_manage?" do
    protocol=protocols(:protocol_with_project_without_gatekeeper)
    assert !protocol.can_manage?,"The protocol must not be manageable for this test to succeed"
    post :publish,:id=>protocol
    assert_redirected_to protocol
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "get preview_publish" do
    login_as(:owner_of_my_first_protocol)
    protocol=protocols(:protocol_with_project_without_gatekeeper)
    assert protocol.can_manage?,"The protocol must be manageable for this test to succeed"
    get :preview_publish, :id=>protocol
    assert_response :success
  end

  test "cannot get preview_publish when not manageable" do
    protocol=protocols(:my_first_protocol)
    assert !protocol.can_manage?,"The protocol must not be manageable for this test to succeed"
    get :preview_publish, :id=>protocol
    assert_redirected_to protocol
    assert flash[:error]
  end

  test 'should show <Not specified> for  other creators if no other creators' do
    get :index
    assert_response :success
    no_other_creator_protocols = assigns(:protocols).select { |s| s.other_creators.blank? }
    assert_select 'p.list_item_attribute', :text => /Other creator: Not specified/, :count => no_other_creator_protocols.count
  end

  test "should set the policy to sysmo_and_projects if the item is requested to be published, when creating new protocol" do
    gatekeeper = Factory(:gatekeeper)
    post :create, :protocol => {:title => 'test', :projects => gatekeeper.projects, :data => fixture_file_upload('files/file_picture.png')}, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
    protocol = assigns(:protocol)
    assert_redirected_to (protocol)
    policy = protocol.policy
    assert_equal Policy::ALL_SYSMO_USERS , policy.sharing_scope
    assert_equal Policy::VISIBLE, policy.access_type
    assert_equal 1, policy.permissions.count
    assert_equal gatekeeper.projects.first, policy.permissions.first.contributor
    assert_equal Policy::ACCESSIBLE, policy.permissions.first.access_type
  end

  test "should not change the policy if the item is requested to be published, when managing protocol" do
      gatekeeper = Factory(:gatekeeper)
      policy = Factory(:policy, :sharing_scope => Policy::PRIVATE, :permissions => [Factory(:permission)])
      protocol = Factory(:protocol, :projects => gatekeeper.projects, :policy => policy)
      login_as(protocol.contributor)
      assert protocol.can_manage?
      put :update, :id => protocol.id, :protocol =>{}, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
      protocol = assigns(:protocol)
      assert_redirected_to(protocol)
      updated_policy = protocol.policy
      assert_equal policy, updated_policy
      assert_equal policy.permissions, updated_policy.permissions
  end
  private

  def valid_protocol_with_url
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"
    {:title=>"Test", :data_url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png",:projects=>[projects(:sysmo_project)]}
  end

  def valid_protocol
    {:title=>"Test", :data=>fixture_file_upload('files/file_picture.png'),:projects=>[projects(:sysmo_project)]}
  end

end
