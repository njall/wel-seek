require 'test_helper'

class UuidsControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper
  
  def setup
    login_as(:quentin)
  end
  
  test "show" do
    m=models(:model_with_format_and_type)
    get :show, :id=>m.uuid
    assert_redirected_to m
  end
  
  test "show2" do
    experiment=experiments(:metabolomics_experiment2)
    get :show, :id=>experiment.uuid
    assert_redirected_to experiment
  end
  
end
