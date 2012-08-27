require 'test_helper'
require 'pubmed_query'

class PublicationTest < ActiveSupport::TestCase
  
  fixtures :all

  test "event association" do
    publication = publications(:one)
    assert publication.events.empty?
    event = events(:event_with_no_files)
    User.with_current_user(publication.contributor) do
      publication.events << event
      assert publication.valid?
      assert publication.save
    end
    assert_equal 1, publication.events.count
  end

  test "experiment association" do
    publication = publications(:pubmed_2)
    experiment = experiments(:modelling_experiment_with_data_and_relationship)
    User.current_user = experiment.contributor.user
    experiment_asset = experiment_assets(:metabolomics_experiment_asset1)
    assert_not_equal experiment_asset.asset, publication
    assert_not_equal experiment_asset.experiment, experiment
    experiment_asset.asset = publication
    experiment_asset.experiment = experiment
    User.with_current_user(experiment.contributor.user) {experiment_asset.save!}
    experiment_asset.reload
    assert experiment_asset.valid?
    assert_equal experiment_asset.asset, publication
    assert_equal experiment_asset.experiment, experiment

  end

  test "publication date from pubmed" do
    WebMock.allow_net_connect!
    query = PubmedQuery.new("seek","sowen@cs.man.ac.uk")
    result = query.fetch(21533085)
    assert_equal Date.parse("20 April 2011"),result.date_published

    sleep 0.5 #the sleeps are to keep in accordance to the pubmed service requirements
    result = query.fetch(1)
    assert_equal Date.parse("1 June 1975"),result.date_published

    sleep 0.5 #the sleeps are to keep in accordance to the pubmed service requirements
    result = query.fetch(20533085)
    assert_equal Date.parse("9 June 2010"),result.date_published
  end

  test "book chapter doi" do
    WebMock.allow_net_connect!
    query=DoiQuery.new("sowen@cs.man.ac.uk")
    result = query.fetch("10.1007/978-3-642-16239-8_8")
    assert_equal 3,result.publication_type
    assert_equal "Prediction with Confidence Based on a Random Forest Classifier",result.title
    assert_equal 2,result.authors.size
    last_names = ["Devetyarov","Nouretdinov"]
    result.authors.each do |auth|
      assert last_names.include? auth.last_name
    end
    
    assert_equal "Artificial Intelligence Applications and Innovations",result.journal
    assert_equal Date.parse("1 Jan 2010"),result.date_published
    assert_equal "10.1007/978-3-642-16239-8_8",result.doi

  end

  test "editor should not be author" do
    WebMock.allow_net_connect!
    query=DoiQuery.new("sowen@cs.man.ac.uk")
    result = query.fetch("10.1371/journal.pcbi.1002352")
    assert !result.authors.collect{|auth| auth.last_name}.include?("Papin")
    assert_equal 5,result.authors.size
  end

  test "model and datafile association" do
    publication = publications(:pubmed_2)
    assert publication.related_models.include?(models(:teusink))
    assert publication.related_data_files.include?(data_files(:picture))
  end

  test "test uuid generated" do
    x = publications(:one)
    assert_nil x.attributes["uuid"]
    x.save    
    assert_not_nil x.attributes["uuid"]
  end

  test "sort by published_date" do
    assert_equal Publication.find(:all).sort_by { |p| p.published_date}.reverse, Publication.find(:all)
  end
  
  test "title trimmed" do
    x = Factory :publication, :title => " a pub"
    assert_equal("a pub",x.title)
  end

  test "validation" do
    asset=Publication.new :title=>"fred",:projects=>[projects(:sysmo_project)],:doi=>"111"
    assert asset.valid?

    asset=Publication.new :title=>"fred",:projects=>[projects(:sysmo_project)],:pubmed_id=>"111"
    assert asset.valid?

    asset=Publication.new :title=>"fred",:projects=>[projects(:sysmo_project)]
    assert !asset.valid?

    asset=Publication.new :projects=>[projects(:sysmo_project)],:doi=>"111"
    assert !asset.valid?

    asset=Publication.new :title=>"fred",:doi=>"111"
    assert !asset.valid?
  end
  
  test "creators order is returned in the order they were added" do
    p=Factory :publication
    assert_equal 0,p.creators.size
    
    p1=people(:modeller_person)
    p2=people(:fred)    
    p3=people(:aaron_person)
    p4=people(:pal)

    User.with_current_user(p.contributor) do
      p.creators << p1
      p.creators << p2
      p.creators << p3
      p.creators << p4

      p.save!
    end
    
    assert_equal 4,p.creators.size
    assert_equal [p1,p2,p3,p4],p.creators
  end
  
  test "uuid doesn't change" do
    x = publications(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  def test_project_required
    p=Publication.new(:title=>"blah blah blah",:pubmed_id=>"123")
    assert !p.valid?
    p.projects=[projects(:sysmo_project)]
    assert p.valid?
  end
  
end
