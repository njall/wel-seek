require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  test "creatable types" do
    assert_equal [DataFile,Model,Presentation,Publication,Protocol,Experiment,Investigation,Study,Event,Sample],Seek::Util.user_creatable_types
  end

  test "authorized types" do
    assert_equal [Experiment, DataFile, Event, Investigation, Model, Presentation, Publication, Sample, Protocol, Specimen, Strain, Study],Seek::Util.authorized_types
  end
end
