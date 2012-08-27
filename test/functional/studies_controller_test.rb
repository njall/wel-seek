require 'test_helper'

class StudiesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:quentin)
    @object=Factory :study, :policy => Factory(:public_policy)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    studies = assigns(:studies)
    first_study = studies.first
    assert_not_nil first_study
    assert_select "a[id*=?]",/drag_Study_#{first_study.id}/
  end
  
  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK Studies.*/, :count=>1
  end

  test "should get show" do
    get :show, :id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get new with investigation predefined even if not member of project" do
    #this scenario arose whilst fixing the test "should get new with investigation predefined"
    #when passing the investigation_id, if that is editable but current_user is not a member,
    #then the investigation should be added to the list
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?,"model owner should be able to edit this investigation"
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",inv.id
    end
  end

  test "should get new with investigation predefined" do
    login_as :model_owner
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?,"model owner should be able to edit this investigation"
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",inv.id
    end
  end

  test "should not allow linking to an investigation from a project you are not a member of" do
    login_as(:owner_of_my_first_protocol)
    inv = investigations(:metabolomics_investigation)
    assert !inv.projects.map(&:people).flatten.include?(people(:person_for_owner_of_my_first_protocol)), "this person should not be a member of the investigations project"
    assert !inv.can_edit?(users(:owner_of_my_first_protocol))
    get :new, :investigation_id=>inv
    assert_response :success

    assert_select "select#study_investigation_id" do
      assert_select "option[selected='selected'][value=?]",0
    end

    assert_not_nil flash.now[:error]
  end


  test "should get edit" do
    get :edit,:id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end  
  
  test "shouldn't show edit for unauthorized users" do
    s = Factory :study, :policy => Factory(:private_policy)
    login_as(Factory(:user))
    get :edit, :id=>s
    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test "should update" do
    s=studies(:metabolomics_study)
    assert_not_equal "test",s.title
    put :update,:id=>s.id,:study=>{:title=>"test"}
    s=assigns(:study)
    assert_redirected_to study_path(s)
    assert_equal "test",s.title
  end

  test "should create" do
    assert_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation)}
    end
    s=assigns(:study)
    assert_redirected_to study_path(s)
  end  

  test "should update sharing permissions" do
    login_as(Factory(:user))
    s = Factory :study,:contributor => User.current_user.person, :policy => Factory(:public_policy)
    assert s.can_manage?(User.current_user),"This user should be able to manage this study"
    
    assert_equal Policy::MANAGING,s.policy.sharing_scope
    assert_equal Policy::EVERYONE,s.policy.access_type

    put :update,:id=>s,:study=>{},:sharing=>{"access_type_#{Policy::NO_ACCESS}"=>Policy::NO_ACCESS,:sharing_scope=>Policy::PRIVATE}
    s=assigns(:study)
    assert_response :redirect
    s.reload
    assert_equal Policy::PRIVATE,s.policy.sharing_scope
    assert_equal Policy::NO_ACCESS,s.policy.access_type
  end

  test "should not update sharing permissions to remove your own manage rights" do
    login_as(Factory(:user))
    s = Factory :study,:contributor => Factory(:person), :policy => Factory(:public_policy)
    assert s.can_manage?(User.current_user),"This user should be able to manage this study"

    assert_equal Policy::MANAGING, s.policy.sharing_scope
    assert_equal Policy::EVERYONE, s.policy.access_type

    put :update,:id=>s,:study=>{},:sharing=>{"access_type_#{Policy::NO_ACCESS}"=>Policy::NO_ACCESS,:sharing_scope=>Policy::PRIVATE}
    s=assigns(:study)
    assert_response :success
    s.reload
    assert_equal Policy::MANAGING, s.policy.sharing_scope
    assert_equal Policy::EVERYONE, s.policy.access_type
  end

  test "should not create with experiment already related to study" do
    assert_no_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation),:experiment_ids=>[experiments(:metabolomics_experiment3).id]}
    end
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect        
  end

  test "should not update with experiment already related to study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"test",:experiment_ids=>[experiments(:metabolomics_experiment3).id]}
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect
  end

  test "should can update with experiment already related to this study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"new title",:experiment_ids=>[experiments(:metabolomics_experiment).id]}
    s=assigns(:study)
    assert !flash[:error]
    assert_redirected_to study_path(s)
    assert_equal "new title",s.title
    assert s.experiments.include?(experiments(:metabolomics_experiment))
  end

  test "no edit button shown for people who can't edit the study" do
    login_as Factory(:user)
    study = Factory :study, :policy => Factory(:private_policy)
    get :show, :id=>study
    assert_select "a",:text=>/Edit study/,:count=>0
  end

  test "edit button in show for person in project" do
    get :show, :id=>studies(:metabolomics_study)
    assert_select "a",:text=>/Edit study/,:count=>1
  end


  test "unauthorized user can't update" do
    s=Factory :study, :policy => Factory(:private_policy)
    login_as(Factory(:user))
    Factory :permission, :contributor => User.current_user, :policy=> s.policy, :access_type => Policy::VISIBLE

    put :update, :id=>s.id,:study=>{:title=>"test"}

    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test "authorized user can delete if no experiments" do
    study = Factory(:study, :contributor => Factory(:person))
    login_as study.contributor.user
    assert_difference('Study.count',-1) do
      delete :destroy, :id => study.id
    end    
    assert !flash[:error]
    assert_redirected_to studies_path
  end

  test "study non project member cannot delete even if no experiments" do
    login_as(:aaron)
    assert_no_difference('Study.count') do
      delete :destroy, :id => studies(:study_with_no_experiments).id
    end
    assert flash[:error]
    assert_redirected_to studies_path
  end
  
  test "study project member cannot delete if experiments associated" do
    assert_no_difference('Study.count') do
      delete :destroy, :id => studies(:metabolomics_study).id
    end
    assert flash[:error]
    assert_redirected_to studies_path
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> studies(:study_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  test "should show svg item" do
    get :show, :id=>studies(:study_with_links_in_description),:format=>"svg"
    assert_response :success    
    assert @response.body.include?("Generated by Graphviz"), "SVG generation failed, please make you you have graphviz installed, and the 'dot' command is available"
  end

  def test_experiment_tab_doesnt_show_private_protocols_or_datafiles
    login_as(:model_owner)
    study=studies(:study_with_experiment_with_public_private_protocols_and_datafile)
    get :show,:id=>study
    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"Experiments (1)",:count=>1
      assert_select "h3",:text=>"Protocols (1+1)",:count=>1
      assert_select "h3",:text=>"Data Files (1+1)",:count=>1
    end
    
    assert_select "div.list_item" do
      #the Experiment resource_list_item
      assert_select "p.list_item_attribute a[title=?]",protocols(:protocol_with_fully_public_policy).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",protocol_path(protocols(:protocol_with_fully_public_policy)),:count=>1
      assert_select "p.list_item_attribute a[title=?]",protocols(:protocol_with_private_policy_and_custom_sharing).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",protocol_path(protocols(:protocol_with_private_policy_and_custom_sharing)),:count=>0

      assert_select "p.list_item_attribute a[title=?]",data_files(:downloadable_data_file).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:downloadable_data_file)),:count=>1
      assert_select "p.list_item_attribute a[title=?]",data_files(:private_data_file).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0

      #the Protocols and DataFiles resource_list_item
      assert_select "div.list_item_title a[href=?]",protocol_path(protocols(:protocol_with_fully_public_policy)),:text=>"Protocol with fully public policy",:count=>1
      assert_select "div.list_item_actions a[href=?]",protocol_path(protocols(:protocol_with_fully_public_policy)),:count=>1
      assert_select "div.list_item_title a[href=?]",protocol_path(protocols(:protocol_with_private_policy_and_custom_sharing)),:count=>0
      assert_select "div.list_item_actions a[href=?]",protocol_path(protocols(:protocol_with_private_policy_and_custom_sharing)),:count=>0

      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:downloadable_data_file)),:text=>"Download Only",:count=>1
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:downloadable_data_file)),:count=>1
      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:private_data_file)),:count=>0
    end
  end

  def test_should_show_investigation_tab
    s=studies(:metabolomics_study)
    get :show,:id=>s
    assert_response :success
    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"Investigations (1)",:count=>1
    end
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


  test 'edit study with selected projects scope policy' do
    proj = User.current_user.person.projects.first
    study = Factory(:study, :contributor => User.current_user.person,
                    :investigation => Factory(:investigation, :projects => [proj]),
                    :policy => Factory(:policy,
                                       :sharing_scope => Policy::ALL_SYSMO_USERS,
                                       :access_type => Policy::NO_ACCESS,
                                       :permissions => [Factory(:permission, :contributor => proj, :access_type => Policy::EDITING)]))
    get :edit, :id => study.id
  end

  test 'should show the contributor avatar' do
    study = Factory(:study, :policy => Factory(:public_policy))
    get :show, :id => study
    assert_response :success
    assert_select ".author_avatar" do
      assert_select "a[href=?]",person_path(study.contributing_user.person) do
        assert_select "img"
      end
    end
  end


end
