require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    WebMock.allow_net_connect!
    login_as(:quentin)
    @object=publications(:taverna_paper_pubmed)
  end
  
  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK Publications.*/, :count=>1
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not relate experiments thay are not authorized for edit during create publication" do
    experiment=experiments(:metabolomics_experiment)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 3,:projects=>[projects(:sysmo_project)]},:experiment_ids=>[experiment.id.to_s]
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 0,p.related_experiments.count
  end

  test "should create publication" do
    login_as(:model_owner) #can edit experiment
    experiment=experiments(:metabolomics_experiment)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 3,:projects=>[projects(:sysmo_project)] },:experiment_ids=>[experiment.id.to_s]
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 1,p.related_experiments.count
    assert p.related_experiments.include? experiment
  end
  
  test "should create doi publication" do
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1371/journal.pone.0004803", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end  

  test "should show publication" do
    get :show, :id => publications(:one)
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => publications(:one)
    assert_response :success
  end

  test "associates experiment" do
    login_as(:model_owner) #can edit experiment
    p = publications(:taverna_paper_pubmed)
    original_experiment = experiments(:experiment_with_a_publication)
    assert p.related_experiments.include?(original_experiment)
    assert original_experiment.related_publications.include?(p)

    new_experiment=experiments(:metabolomics_experiment)
    assert new_experiment.related_publications.empty?
    
    put :update, :id => p,:author=>{},:experiment_ids=>[new_experiment.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_experiment.reload
    new_experiment.reload

    assert_equal 1, p.related_experiments.count

    assert !p.related_experiments.include?(original_experiment)
    assert !original_experiment.related_publications.include?(p)

    assert p.related_experiments.include?(new_experiment)
    assert new_experiment.related_publications.include?(p)

  end

  test "do not associate experiments unauthorized for edit" do
    p = publications(:taverna_paper_pubmed)
    original_experiment = experiments(:experiment_with_a_publication)
    assert p.related_experiments.include?(original_experiment)
    assert original_experiment.related_publications.include?(p)

    new_experiment=experiments(:metabolomics_experiment)
    assert new_experiment.related_publications.empty?

    put :update, :id => p,:author=>{},:experiment_ids=>[new_experiment.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_experiment.reload
    new_experiment.reload

    assert_equal 1, p.related_experiments.count

    assert p.related_experiments.include?(original_experiment)
    assert original_experiment.related_publications.include?(p)

    assert !p.related_experiments.include?(new_experiment)
    assert !new_experiment.related_publications.include?(p)

  end

  test "should keep model and data associations after update" do
    p = publications(:pubmed_2)
    put :update, :id => p,:author=>{},:experiment_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload

    assert p.related_experiments.empty?
    assert p.related_models.include?(models(:teusink))
    assert p.related_data_files.include?(data_files(:picture))
  end


  test "should associate authors" do
    p = publications(:pubmed_2)
    assert_equal 2, p.non_seek_authors.size
    assert_equal 0, p.creators.size
    
    seek_author1 = people(:modeller_person)
    seek_author2 = people(:quentin_person)    
    
    #Associate a non-seek author to a seek person

    #Check the non_seek_authors (PublicationAuthors) decrease by 1, and the
    # seek_authors (AssetsCreators) increase by 1.
    assert_difference('PublicationAuthor.count', -2) do
      assert_difference('AssetsCreator.count', 2) do
        put :update, :id => p.id, :author => {p.non_seek_authors[1].id => seek_author2.id,p.non_seek_authors[0].id => seek_author1.id}
      end
    end
    
    assert_redirected_to publication_path(p)    
    p.reload
    
    #make sure that the authors are stored according to key, and that creators keeps the order
    assert_equal [seek_author1,seek_author2],p.assets_creators.sort_by(&:id).collect(&:creator)
    assert_equal [seek_author1,seek_author2],p.creators
  end
  
  test "should disassociate authors" do
    p = publications(:one)
    p.creators << people(:quentin_person)
    p.creators << people(:aaron_person)
    
    assert_equal 0, p.non_seek_authors.size
    assert_equal 2, p.creators.size
    
    #Check the non_seek_authors (PublicationAuthors) increase by 2, and the
    # seek_authors (AssetsCreators) decrease by 2.
    assert_difference('PublicationAuthor.count', 2) do
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, :id => p.id
      end 
    end

  end

  test "should update project" do
    p = publications(:one)
    assert_equal projects(:sysmo_project), p.projects.first
    put :update, :id => p.id, :author => {}, :publication => {:project_ids => [projects(:one).id]}
    assert_redirected_to publication_path(p)
    p.reload
    assert_equal [projects(:one)], p.projects
  end

  test "should destroy publication" do
    assert_difference('Publication.count', -1) do
      delete :destroy, :id => publications(:one).to_param
    end

    assert_redirected_to publications_path
  end
  
  test "shouldn't add paper with non-unique title" do
    #PubMed version of publication already exists, so it shouldn't re-add
    assert_no_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1093/nar/gkl320" }
    end
  end
end
