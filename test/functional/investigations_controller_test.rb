require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:quentin)
    @object= Factory(:investigation, :policy => Factory(:public_policy))
  end

  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK Investigations.*/, :count=>1
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:investigations)
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    investigations = assigns(:investigations)
    first_investigations = investigations.first
    assert_not_nil first_investigations
    assert_select "a[id*=?]",/drag_Investigation_#{first_investigations.id}/
  end

  test "should show item" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert_not_nil assigns(:investigation)
  end
  
  test "should show svg item" do
    get :show, :id=>investigations(:metabolomics_investigation),:format=>"svg"
    assert_response :success    
    assert @response.body.include?("Generated by Graphviz"), "SVG generation failed, please make you you have graphviz installed, and the 'dot' command is available"
  end

  test "should show new" do
    get :new
    assert_response :success
    assert assigns(:investigation)
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to investigations_path
  end

  test "should show edit" do
    get :edit, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert assigns(:investigation)
  end
  
  test "shouldn't show edit for unauthorized user" do
    i = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, :id=>i
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "should update" do
    i=investigations(:metabolomics_investigation)
    put :update, :id=>i.id,:investigation=>{:title=>"test"}
    
    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert_equal "test",assigns(:investigation).title
  end

  test "should create" do
    login_as(Factory :user)
    assert_difference("Investigation.count") do
      put :create, :investigation=> Factory.attributes_for(:investigation, :projects => [User.current_user.person.projects.first])
    end
    assert assigns(:investigation)
    assert !assigns(:investigation).new_record?
  end

  test "should fall back to form when no title validation fails" do
    login_as(Factory :user)

    assert_no_difference("Investigation.count") do
      put :create, :investigation=> {:projects => [User.current_user.person.projects.first]}
    end
    assert_template :new
    
    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?

  end

  test "should fall back to form when no projects validation fails" do
    login_as(Factory :user)

    assert_no_difference("Investigation.count") do
      put :create, :investigation=> {:title=>"investigation with no projects"}
    end
    assert_template :new

    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?

  end

  test "no edit button in show for unauthorized user" do
    login_as(Factory(:user))
    get :show, :id=>Factory(:investigation, :policy => Factory(:private_policy))
    assert_select "a",:text=>/Edit investigation/,:count=>0
  end

  test "edit button in show for authorized user" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_select "a[href=?]",edit_investigation_path(investigations(:metabolomics_investigation)),:text=>/Edit investigation/,:count=>1
  end

  test "no add study button for person that can edit" do
    login_as(:owner_of_my_first_protocol)
    inv = investigations(:metabolomics_investigation)
    assert !inv.can_edit?,"Aaron should not be able to edit this investigation"
    get :show, :id=>inv
    assert_select "a",:text=>/Add a study/,:count=>0
  end

  test "add study button for person that can edit" do
    inv = investigations(:metabolomics_investigation)
    get :show, :id=>inv
    assert_select "a[href=?]",new_study_path(:investigation_id=>inv),:text=>/Add a study/,:count=>1
  end


  test "unauthorized user can't edit investigation" do
    i=Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, :id=>i
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "unauthorized users can't update investigation" do
    i=Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    put :update, :id=>i.id,:investigation=>{:title=>"test"}

    assert_redirected_to investigation_path(i)
  end

  test "should destroy investigation" do
    i = Factory(:investigation, :contributor => User.current_user)
    assert_difference("Investigation.count",-1) do
      delete :destroy, :id => i.id
    end
    assert !flash[:error]
    assert_redirected_to investigations_path    
  end

  test "unauthorized user should not destroy investigation" do
    i = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(Factory(:user))
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => i.id
    end
    assert flash[:error]
    assert_redirected_to investigations_path    
  end

  test "should not destroy investigation with a study" do
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => investigations(:metabolomics_investigation).id
    end
    assert flash[:error]
    assert_redirected_to investigations_path    
  end

  test "option to delete investigation without study" do    
    get :show,:id=>Factory(:investigation, :contributor => User.current_user).id
    assert_select "a",:text=>/Delete Investigation/,:count=>1
  end

  test "no option to delete investigation with study" do
    get :show,:id=>investigations(:metabolomics_investigation).id
    assert_select "a",:text=>/Delete Investigation/,:count=>0
  end

  test "no option to delete investigation when unauthorized" do
    i = Factory :investigation, :policy => Factory(:private_policy)
    login_as Factory(:user)
    get :show,:id=>i.id
    assert_select "a",:text=>/Delete Investigation/,:count=>0
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> investigations(:investigation_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test 'should show the contributor avatar' do
    investigation = Factory(:investigation, :policy => Factory(:public_policy))
    get :show, :id => investigation
    assert_response :success
    assert_select ".author_avatar" do
      assert_select "a[href=?]",person_path(investigation.contributing_user.person) do
        assert_select "img"
      end
    end
  end
end
