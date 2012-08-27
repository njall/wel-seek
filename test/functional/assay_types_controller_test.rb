require 'test_helper'

class ExperimentTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
    @object=experiment_types(:metabolomics)
  end

  test "show" do
    login_as(:quentin)
    get :show,:id=>experiment_types(:metabolomics)
    assert_response :success
  end

  test "should show manage page" do
    login_as(:quentin)
    get :manage
    assert_response :success
    assert_not_nil assigns(:experiment_types)
  end
  
  test "should not show manage page for non-admin" do
    login_as(:cant_edit)
    get :manage
    assert flash[:error]
    assert_redirected_to root_url
  end

  test "should not show manage page for pal" do
    login_as(:pal_user)
    get :manage
    assert flash[:error]
    assert_redirected_to root_url
  end
  
  test "should show new" do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_not_nil assigns(:experiment_type)
  end
  
  test "should show edit" do
    login_as(:quentin)
    get :edit, :id=>experiment_types(:experiment_type_with_child).id
    assert_response :success
    assert_not_nil assigns(:experiment_type)
  end
  
  test "should create" do
    login_as(:quentin)
    assert_difference("ExperimentType.count") do
      post :create,:experiment_type=>{:title => "test_experiment_type", :parent_id => [experiment_types(:experiment_type_with_child_and_experiment).id]}
    end
    experiment_type = assigns(:experiment_type)
    assert experiment_type.valid?
    assert_equal 1,experiment_type.parents.size
    assert_redirected_to manage_experiment_types_path
  end
  
  test "should update title" do
    login_as(:quentin)
    experiment_type = experiment_types(:child_experiment_type)
    put :update, :id => experiment_type.id, :experiment_type => {:title => "child_experiment_type_a", :parent_id => experiment_type.parents.collect {|p| p.id}}
    assert assigns(:experiment_type)
    assert_equal "child_experiment_type_a", assigns(:experiment_type).title
  end
  
  test "should update parents" do
    login_as(:quentin)
    experiment_type = experiment_types(:child_experiment_type)
    assert_equal 1,experiment_type.parents.size
    put :update,:id=>experiment_type.id,:experiment_type=>{:title => experiment_type.title, :parent_id => (experiment_type.parents.collect {|p| p.id} + [experiment_types(:new_parent)])}
    assert assigns(:experiment_type)
    assert_equal 2,assigns(:experiment_type).parents.size
    assert_equal assigns(:experiment_type).parents.last, experiment_types(:new_parent)
  end
  
  test "should delete experiment" do
    login_as(:quentin)
    experiment_type = ExperimentType.create(:title => "delete_me")
    assert_difference('ExperimentType.count', -1) do
      delete :destroy, :id => experiment_type.id
    end
    assert_nil flash[:error]
    assert_redirected_to manage_experiment_types_path
  end
  
  test "should not delete experiment_type with child" do
    login_as(:quentin)
    assert_no_difference('ExperimentType.count') do
      delete :destroy, :id => experiment_types(:experiment_type_with_child).id
    end
    assert flash[:error]
    assert_redirected_to manage_experiment_types_path
  end 
  
  test "should not delete experiment_type with experiments" do
    login_as(:quentin)
    assert_no_difference('ExperimentType.count') do
      delete :destroy, :id => experiment_types(:child_experiment_type_with_experiment).id
    end
    assert flash[:error]
    assert_redirected_to manage_experiment_types_path
  end
  
  test "should not delete experiment_type with children with experiments" do
    login_as(:quentin)
    assert_no_difference('ExperimentType.count') do
      delete :destroy, :id => experiment_types(:experiment_type_with_only_child_experiments).id
    end
    assert flash[:error]
    assert_redirected_to manage_experiment_types_path
  end

  test "should show experiment types to public" do
    logout
    get :show, :id => experiment_types(:metabolomics)
    assert_response :success
    assert_not_nil assigns(:experiment_type)
  end

  test 'should show only related authorized experiments' do
    experiments = experiment_types(:child_experiment_type_with_experiment).experiments
    authorized_experiments = experiments.select(&:can_view?)
    assert_equal 2, experiments.count
    assert_equal 1, authorized_experiments.count

    get :show, :id => experiment_types(:child_experiment_type_with_experiment)
    assert_response :success
    assert_select 'a', :text => authorized_experiments.first.title, :count => 1
    assert_select 'a', :text => (experiments - authorized_experiments).first.title, :count => 0
  end
end
