require 'test_helper'

class ExperimentClassTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "for_type" do
    assert_equal "EXP",ExperimentClass.for_type("experimental").key
    assert_equal "MODEL",ExperimentClass.for_type("modelling").key
  end
end
