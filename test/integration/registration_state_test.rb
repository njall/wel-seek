require 'test_helper'

class RegistrationStateTest < ActionController::IntegrationTest
  include AuthenticatedTestHelper
  fixtures :all

  test "partially registered user always redirects to select person" do
    
    User.current_user = Factory(:user, :login => 'partial',:person=>nil)
    post '/sessions/create', :login => 'partial', :password => 'blah'
    assert_redirected_to select_people_path

    assert_nil User.current_user.person

    get "/people/select"
    assert_response :success

    get "/session/new"
    assert_response :success

    xml_http_request :post,'people/userless_project_selected_ajax',{:project_id=>Factory(:project).id}
    assert_response :success

    get people_path
    assert_redirected_to select_people_path

    get models_path
    assert_redirected_to select_people_path

    get root_path
    assert_redirected_to select_people_path

    get protocol_path(Factory :protocol)
    assert_redirected_to select_people_path

    get "/logout"
    assert_redirected_to root_path

  end

end