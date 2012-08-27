require 'test_helper'

class ModelsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  
  def setup
    login_as(:model_owner)
    @object=models(:teusink)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:models)
  end    
  
  test "should not create model with file url" do
    file_path=File.expand_path(__FILE__) #use the current file
    file_url="file://"+file_path
    uri=URI.parse(file_url)    
   
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => { :title=>"Test",:data_url=>uri.to_s}, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash[:error]    
  end

  test 'creators show in list item' do
    p1=Factory :person
    p2=Factory :person
    model=Factory(:model,:title=>"ZZZZZ",:creators=>[p2],:contributor=>p1.user,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))

    get :index,:page=>"Z"

    #check the test is behaving as expected:
    assert_equal p1.user,model.contributor
    assert model.creators.include?(p2)
    assert_select ".list_item_title a[href=?]",model_path(model),"ZZZZZ","the data file for this test should appear as a list item"

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
  
  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:models).sort_by(&:id), Authorization.authorize_collection("view", assigns(:models), users(:aaron)).sort_by(&:id), "models haven't been authorized properly"
  end

  test "should contain only model experiments " do
    login_as(:aaron)
    experiment = experiments(:metabolomics_experiment)
    assert_equal false, experiment.is_modelling?
    experiment = experiments(:modelling_experiment_with_data_and_relationship)
    assert_equal true, experiment.is_modelling?

  end

  test "should show only modelling experiments in associate experiment form" do
    login_as(:model_owner)
    get :new
    assert_response :success
    assert_select 'select#possible_experiments' do
      assert_select "option", :text=>/Select Experiment .../,:count=>1
      assert_select "option", :text=>/Modelling Experiment/,:count=>1
      assert_select "option", :text=>/Metabolomics Experiment/,:count=>0
    end
  end

  test "fail gracefullly when trying to access a missing model" do
    get :show,:id=>99999
    assert_redirected_to models_path
    assert_not_nil flash[:error]
  end
  
  test "should get new" do
    get :new    
    assert_response :success
    assert_select "h1",:text=>"New Model"
  end    
  
  test "should correctly handle bad data url" do
    model={:title=>"Test",:data_url=>"http://sdfsdfkh.com/sdfsd.png",:projects=>[projects(:sysmo_project)]}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should not create invalid model" do
    model={:title=>"Test"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
    test "associates experiment" do
    login_as(:model_owner) #can edit experiment_can_edit_by_my_first_protocol_owner
    m = models(:teusink)
    original_experiment = experiments(:experiment_with_a_model)
    asset_ids = original_experiment.related_asset_ids 'Model'
    assert asset_ids.include? m.id
    new_experiment=experiments(:modelling_experiment)
    new_asset_ids = new_experiment.related_asset_ids 'Model'
    assert !new_asset_ids.include?(m.id)

    put :update, :id => m, :model =>{}, :experiment_ids=>[new_experiment.id.to_s]

    assert_redirected_to model_path(m)
    m.reload
    original_experiment.reload
    new_experiment.reload
    assert !original_experiment.related_asset_ids('Model').include?(m.id)
    assert new_experiment.related_asset_ids('Model').include?(m.id)
    end

  test "should create model" do
    login_as(:model_owner)
    experiment = experiments(:modelling_experiment)
    assert_difference('Model.count') do
      post :create, :model => valid_model, :sharing=>valid_sharing, :experiment_ids => [experiment.id.to_s]
    end
    
    assert_redirected_to model_path(assigns(:model))
    experiment.reload
    assert experiment.related_asset_ids('Model').include? assigns(:model).id
  end
  
  def test_missing_sharing_should_default_to_private
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => valid_model
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert assigns(:model)
    
    model=assigns(:model)
    private_policy = policies(:private_policy_for_asset_of_my_first_protocol)
    assert_equal private_policy.sharing_scope,model.policy.sharing_scope
    assert_equal private_policy.access_type,model.policy.access_type
    assert_equal private_policy.use_whitelist,model.policy.use_whitelist
    assert_equal private_policy.use_blacklist,model.policy.use_blacklist
    assert model.policy.permissions.empty?
    
    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success    
  end
  
  test "should create model with url" do
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => valid_model_with_url, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor   
    assert !assigns(:model).content_blob.url.blank?
    assert assigns(:model).content_blob.data_io_object.nil?
    assert !assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end
  
  test "should create model and store with url and store flag" do
    model_details=valid_model_with_url
    model_details[:local_copy]="1"
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => model_details, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert !assigns(:model).content_blob.url.blank?
    assert !assigns(:model).content_blob.data_io_object.read.nil?
    assert assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end  
  
  test "should create with preferred environment" do
    assert_difference('Model.count') do
      model=valid_model
      model[:recommended_environment_id]=recommended_model_environments(:jws).id
      post :create, :model => model, :sharing=>valid_sharing
    end
    
    m=assigns(:model)
    assert m
    assert_equal "JWS Online",m.recommended_environment.title
  end
  
  test "should show model" do
    m = models(:teusink)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should show model with format and type" do
    m = models(:model_with_format_and_type)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => models(:teusink)
    assert_response :success
    assert_select "h1",:text=>/Editing Model/
  end
  
  test "publications included in form for model" do
    
    get :edit, :id => models(:teusink)
    assert_response :success
    assert_select "div#publications_fold_content",true
    
    get :new
    assert_response :success
    assert_select "div#publications_fold_content",true
  end
  
  test "should update model" do
    put :update, :id => models(:teusink).id, :model => { }
    assert_redirected_to model_path(assigns(:model))
  end
  
  test "should update model with model type and format" do
    type=model_types(:ODE)
    format=model_formats(:SBML)
    put :update, :id => models(:teusink).id, :model => {:model_type_id=>type.id,:model_format_id=>format.id }
    assert assigns(:model)
    assert_equal type,assigns(:model).model_type
    assert_equal format,assigns(:model).model_format
  end
  
  test "should destroy model" do
    assert_difference('Model.count', -1) do
      assert_no_difference("ContentBlob.count") do
        delete :destroy, :id => models(:teusink).id
      end
    end
    
    assert_redirected_to models_path
  end
  
  test "should add model type" do
    login_as(:quentin)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model type as pal" do
    login_as(:pal_user)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model type as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>m.title
    end
    
  end
  
  test "should add model format" do
    login_as(:quentin)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model format as pal" do
    login_as(:pal_user)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model format as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>m.title
    end
    
  end
  
  test "should update model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model format as pal" do
    login_as(:pal_user)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model format as non pal" do
    login_as(:aaron)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type as pal" do
    login_as(:pal_user)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model type as non pal" do
    login_as(:aaron)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  def test_should_show_version
    m = models(:model_with_format_and_type)
    m.save! #to force creation of initial version (fixtures don't include it)
    old_desc=m.description
    old_desc_regexp=Regexp.new(old_desc)
    
    #create new version
    m.description="This is now version 2"
    assert m.save_as_new_version
    m = Model.find(m.id)
    assert_equal 2, m.versions.size
    assert_equal 2, m.version
    assert_equal 1, m.versions[0].version
    assert_equal 2, m.versions[1].version
    
    get :show, :id=>models(:model_with_format_and_type)
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"2"
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"1"
    assert_select "p", :text=>/This is now version 2/, :count=>0
    assert_select "p", :text=>old_desc_regexp, :count=>1
    
  end
  
  def test_should_create_new_version
    m=models(:model_with_format_and_type)    
    
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :model=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision"
    end
    
    assert_redirected_to model_path(m)
    assert assigns(:model)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    
    
    m=Model.find(m.id)
    assert_equal 2,m.versions.size
    assert_equal 2,m.version
    assert_equal "file_picture.png",m.original_filename
    assert_equal "file_picture.png",m.versions[1].original_filename
    assert_equal "Teusink.xml",m.versions[0].original_filename
    assert_equal "This is a new revision",m.versions[1].revision_comments
    
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> models(:model_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  def test_update_should_not_overright_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this model
    model=models(:model_with_no_contributor)
    put :update, :id => model, :model => {:title=>"blah blah blah blah" }
    updated_model=assigns(:model)
    assert_redirected_to model_path(updated_model)
    assert_equal "blah blah blah blah",updated_model.title,"Title should have been updated"
    assert_nil updated_model.contributor,"contributor should still be nil"
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
    person = people(:person_for_model_owner)
    get :index,:filter=>{:person=>person.id},:page=>"all"
    assert_response :success    
    m = models(:model_with_format_and_type)
    m2 = models(:model_with_different_owner)
    assert_select "div.list_items_container" do      
      assert_select "a",:text=>m.title,:count=>1
      assert_select "a",:text=>m2.title,:count=>0
    end
  end

  test "should not be able to update sharing without manage rights" do
    login_as(:quentin)
    user = users(:quentin)
    model   = models(:model_with_links_in_description)

    assert model.can_edit?(user), "protocol should be editable but not manageable for this test"
    assert !model.can_manage?(user), "protocol should be editable but not manageable for this test"
    assert_equal Policy::EDITING, model.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to model_path(model)
    model.reload

    assert_equal "new title", model.title
    assert_equal Policy::EDITING, model.policy.access_type, "policy should not have been updated"
  end

  test "owner should be able to update sharing" do
    login_as(:model_owner)
    user = users(:model_owner)
    model   = models(:model_with_links_in_description)

    assert model.can_edit?(user), "protocol should be editable and manageable for this test"
    assert model.can_manage?(user), "protocol should be editable and manageable for this test"
    assert_equal Policy::EDITING, model.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::ALL_SYSMO_USERS, "access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::NO_ACCESS}
    assert_redirected_to model_path(model)
    model.reload
    assert_equal "new title", model.title
    assert_equal Policy::NO_ACCESS, model.policy.access_type, "policy should have been updated"
  end

  test "owner should be able to choose policy 'share with everyone' when creating a model" do
    model={ :title=>"Test",:data=>fixture_file_upload('files/little_file.txt'),:projects=>[projects(:moses_project)]}
    post :create, :model => model, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}"=>Policy::VISIBLE}
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert assigns(:model)

    model=assigns(:model)
    assert_equal Policy::EVERYONE,model.policy.sharing_scope
    assert_equal Policy::VISIBLE,model.policy.access_type
    #check it doesn't create an error when retreiving the index
    get :index
    assert_response :success
  end

  test "owner should be able to choose policy 'share with everyone' when updating a model" do
    login_as(:model_owner)
    user = users(:model_owner)
    model   = models(:teusink_with_project_without_gatekeeper)
    assert model.can_edit?(user), "model should be editable and manageable for this test"
    assert model.can_manage?(user), "model should be editable and manageable for this test"
    assert_equal Policy::EDITING, model.policy.access_type, "data file should have an initial policy with access type for editing"
    put :update, :id => model, :model => {:title=>"new title"}, :sharing=>{:use_whitelist=>"0", :user_blacklist=>"0", :sharing_scope =>Policy::EVERYONE, "access_type_#{Policy::EVERYONE}"=>Policy::VISIBLE}
    assert_redirected_to model_path(model)
    model.reload

    assert_equal "new title", model.title
    assert_equal Policy::EVERYONE, model.policy.sharing_scope, "policy should have been changed to everyone"
    assert_equal Policy::VISIBLE, model.policy.access_type, "policy should have been updated to visible"
  end

  test "update with ajax only applied when viewable" do
    p=Factory :person
    p2=Factory :person
    viewable_model=Factory :model,:contributor=>p2,:policy=>Factory(:publicly_viewable_policy)
    dummy_model=Factory :model

    login_as p.user

    assert viewable_model.can_view?(p.user)
    assert !viewable_model.can_edit?(p.user)

    golf=Factory :tag,:annotatable=>dummy_model,:source=>p2,:value=>"golf"

    xml_http_request :post, :update_annotations_ajax,{:id=>viewable_model,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    viewable_model.reload

    assert_equal ["golf"],viewable_model.annotations.collect{|a| a.value.text}

    private_model=Factory :model,:contributor=>p2,:policy=>Factory(:private_policy)

    assert !private_model.can_view?(p.user)
    assert !private_model.can_edit?(p.user)

    xml_http_request :post, :update_annotations_ajax,{:id=>private_model,:tag_autocompleter_unrecognized_items=>[],:tag_autocompleter_selected_ids=>[golf.value.id]}

    private_model.reload
    assert private_model.annotations.empty?

  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    model = Factory :model,:contributor=>p.user


    assert model.annotations.empty?,"this model should have no tags for the test"

    golf = Factory :tag,:annotatable=>model,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>model,:source=>p2.user,:value=>"sparrow"

    model.reload

    assert_equal ["golf","sparrow"],model.annotations.collect{|a| a.value.text}.sort
    assert_equal [],model.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],model.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>model,:tag_autocompleter_unrecognized_items=>["soup"],:tag_autocompleter_selected_ids=>[golf.value.id]}

    model.reload

    assert_equal ["golf","soup","sparrow"],model.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],model.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],model.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "do publish" do
    model=models(:teusink_with_project_without_gatekeeper)
    assert model.can_manage?,"The protocol must be manageable for this test to succeed"
    post :publish,:id=>model
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "do not publish if not can_manage?" do
    login_as(:quentin)
    model=models(:teusink_with_project_without_gatekeeper)
    assert !model.can_manage?,"The protocol must not be manageable for this test to succeed"
    post :publish,:id=>model
    assert_redirected_to model
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "get preview_publish" do
    model=models(:teusink_with_project_without_gatekeeper)
    assert model.can_manage?,"The protocol must be manageable for this test to succeed"
    get :preview_publish, :id=>model
    assert_response :success
  end

  test "removing an asset should not break show pages for items that have attribution relationships referencing it" do
    model = Factory :model, :contributor => User.current_user
    disable_authorization_checks do
      attribution = Factory :model
      model.relationships.create :object => attribution, :predicate => Relationship::ATTRIBUTED_TO
      model.save!
      attribution.destroy
    end

    get :show, :id => model.id
    assert_response :success

    model.reload
    assert model.relationships.empty?
  end

  test "cannot get preview_publish when not manageable" do
    login_as(:quentin)
    model=models(:teusink_with_project_without_gatekeeper)
    assert !model.can_manage?,"The protocol must not be manageable for this test to succeed"
    get :preview_publish, :id=>model
    assert_redirected_to model
    assert flash[:error]
  end

  test "should set the other creators " do
    model=models(:teusink)
    assert model.can_manage?,"The protocol must be manageable for this test to succeed"
    put :update, :id => model, :model => {:other_creators => 'marry queen'}
    model.reload
    assert_equal 'marry queen', model.other_creators
  end

  test 'should show the other creators on the model index' do
    model=models(:teusink)
    model.other_creators = 'another creator'
    model.save
    get :index

    assert_select 'p.list_item_attribute', :text => /: another creator/, :count => 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    model=models(:teusink)
    model.other_creators = 'another creator'
    model.save
    get :show, :id => model

    assert_select 'div', :text => /another creator/, :count => 1
  end

  def valid_model
    { :title=>"Test",:data=>fixture_file_upload('files/little_file.txt'),:projects=>[projects(:sysmo_project)]}
  end

  def valid_model_with_url
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"
    { :title=>"Test",:data_url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png",:projects=>[projects(:sysmo_project)]}
  end
  
end
