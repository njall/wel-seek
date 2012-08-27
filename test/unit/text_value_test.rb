require 'test_helper'

class TextValueTest < ActiveSupport::TestCase

  test "annotation count" do
    protocol1 = Factory :protocol
    protocol2 = Factory :protocol
    protocol3 = Factory :protocol
    u = Factory :user
    tag = Factory :tag,:annotatable=>protocol1,:source=>u,:value=>"coffee",:attribute_name=>"tag"
    text_value = tag.value
    Factory :tag,:annotatable=>protocol2,:source=>u,:value=>text_value,:attribute_name=>"tag"
    Factory :tag,:annotatable=>protocol3,:source=>u,:value=>text_value,:attribute_name=>"tag"


    assert_equal 3,text_value.annotation_count("tag")

    Factory :tag,:annotatable=>protocol1,:source=>u,:value=>text_value,:attribute_name=>"desc"

    assert_equal 1,text_value.annotation_count("desc")
    assert_equal 4,text_value.annotation_count(["tag","desc"])

    u2 = Factory :user
    Factory :tag,:annotatable=>protocol1,:source=>u2,:value=>text_value,:attribute_name=>"tag"

    assert_equal 4,text_value.annotation_count("tag")
    assert_equal 5,text_value.annotation_count(["tag","desc"])
  end

  test "all tags includes seed values" do
    protocol = Factory :protocol
    u = Factory :user
    coffee = Factory :tag,:annotatable=>protocol,:source=>u,:value=>"coffee",:attribute_name=>"tag"
    tv=TextValue.create :text=>"frog"
    AnnotationValueSeed.create :value=>tv,:attribute=>AnnotationAttribute.find_or_create_by_name("tag")

    assert_equal 2,TextValue.all_tags.count

    assert_equal ["coffee","frog"],TextValue.all_tags.collect{|tv| tv.text}.sort

  end

  test "all tags" do
    protocol = Factory :protocol
    protocol1 = Factory :protocol
    protocol2 = Factory :protocol

    u = Factory :user

    coffee = Factory :tag,:annotatable=>protocol,:source=>u,:value=>"coffee",:attribute_name=>"tag"
    fish = Factory :tag,:annotatable=>protocol1,:source=>u,:value=>"fish",:attribute_name=>"tag"
    soup = Factory :tag,:annotatable=>protocol2,:source=>u,:value=>"soup",:attribute_name=>"tag"
    soup2 = Factory :tag,:annotatable=>protocol,:source=>u,:value=>soup.value,:attribute_name=>"tag"
    spade = Factory :tag,:annotatable=>protocol,:source=>u,:value=>"spade",:attribute_name=>"tool"
    ruby = Factory :tag,:annotatable=>protocol2,:source=>u,:value=>"ruby",:attribute_name=>"expertise"
    fish2 = Factory :tag,:annotatable=>protocol2,:source=>u,:value=>fish.value,:attribute_name=>"expertise"
    blah = Factory :tag,:annotatable=>protocol2,:source=>u,:value=>"blah",:attribute_name=>"desc"

    assert_equal 5,TextValue.all_tags.count
    assert_equal ["coffee","fish","ruby","soup","spade"],TextValue.all_tags.collect{|tv| tv.text}.sort
    assert_equal 1,TextValue.all_tags(["tool"]).count
    assert_equal spade.value,TextValue.all_tags(["tool"])[0]
    assert_equal 2,TextValue.all_tags(["expertise"]).count
    assert_equal ["fish","ruby"],TextValue.all_tags("expertise").collect{|tv| tv.text}.sort
    assert_equal 1,TextValue.all_tags(["desc"]).count
    assert_equal blah.value,TextValue.all_tags("desc")[0]
  end

  test "has attribute_name?" do
    protocol = Factory :protocol
    u = Factory :user
    coffee = Factory :tag,:annotatable=>protocol,:source=>u,:value=>"coffee",:attribute_name=>"tag"
    Factory :tag,:annotatable=>protocol,:source=>u,:value=>coffee.value,:attribute_name=>"title"
    tv=TextValue.create :text=>"frog"
    AnnotationValueSeed.create :value=>tv,:attribute=>AnnotationAttribute.find_or_create_by_name("tag")

    assert tv.has_attribute_name?("tag")
    assert !tv.has_attribute_name?("title")

    assert coffee.value.has_attribute_name?("tag")
    assert coffee.value.has_attribute_name?("title")
    assert !coffee.value.has_attribute_name?("description")
  end

end