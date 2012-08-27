require 'test_helper'


class ExperimentsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:quentin)
    @object=Factory(:experimental_experiment, :policy => Factory(:public_policy))
  end


  test "modelling experiment validates with schema" do
    a=experiments(:modelling_experiment_with_data_and_relationship)
    User.with_current_user(a.study.investigation.contributor) { a.study.investigation.projects << Factory(:project) }
    assert_difference('ActivityLog.count') do
      get :show, :id=>a, :format=>"xml"
    end

    assert_response :success

    validate_xml_against_schema(@response.body)

  end

  test "check Protocol and DataFile drop down contents" do
    user = Factory :user
    project=user.person.projects.first
    login_as user
    protocol = Factory :protocol, :contributor=>user.person,:projects=>[project]
    data_file = Factory :data_file, :contributor=>user.person,:projects=>[project]
    get :new, :class=>"experimental"
    assert_response :success

    assert_select "select#possible_data_files" do
      assert_select "option[value=?]",data_file.id,:text=>/#{data_file.title}/
      assert_select "option",:text=>/#{protocol.title}/,:count=>0
    end

    assert_select "select#possible_protocols" do
      assert_select "option[value=?]",protocol.id,:text=>/#{protocol.title}/
      assert_select "option",:text=>/#{data_file.title}/,:count=>0
    end
  end

  test "index includes modelling validates with schema" do
    get :index, :page=>"all", :format=>"xml"
    assert_response :success
    experiments=assigns(:experiments)
    assert experiments.include?(experiments(:modelling_experiment_with_data_and_relationship)), "This test is invalid as the list should include the modelling experiment"

    validate_xml_against_schema(@response.body)
  end

  test "shouldn't show unauthorized experiments" do
    login_as Factory(:user)
    hidden = Factory(:experimental_experiment, :policy => Factory(:private_policy)) #ensure at least one hidden experiment exists
    get :index, :page=>"all", :format=>"xml"
    assert_response :success
    assert_equal assigns(:experiments).sort_by(&:id), Authorization.authorize_collection("view", assigns(:experiments), users(:aaron)).sort_by(&:id), "experiments haven't been authorized"
    assert !assigns(:experiments).include?(hidden)
  end

  def test_title
    get :index
    assert_select "title", :text=>/The Sysmo SEEK Experiments.*/, :count=>1
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:experiments)
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    experiments = assigns(:experiments)
    first_experiment = experiments.first
    assert_not_nil first_experiment
    assert_select "a[id*=?]", /drag_Experiment_#{first_experiment.id}/
  end

  test "should show index in xml" do
    get :index
    assert_response :success
    assert_not_nil assigns(:experiments)
  end

  test "should update experiment with new version of same protocol" do
    login_as(:model_owner)
    experiment=experiments(:metabolomics_experiment)
    timestamp=experiment.updated_at

    protocol = protocols(:protocol_with_all_sysmo_users_policy)
    assert !experiment.protocols.include?(protocol.latest_version)
    assert_difference('ActivityLog.count') do
      put :update, :id=>experiment, :experiment_protocol_ids=>[protocol.id], :experiment=>{}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to experiment_path(experiment)
    assert assigns(:experiment)

    experiment.reload
    stored_protocol = experiment.experiment_assets.detect { |aa| aa.asset_id=protocol.id }.versioned_asset
    assert_equal protocol.version, stored_protocol.version

    login_as protocol.contributor
    protocol.save_as_new_version
    login_as(:model_owner)

    assert_difference('ActivityLog.count') do
      put :update, :id=>experiment, :experiment_protocol_ids=>[protocol.id], :experiment=>{}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    experiment.reload
    stored_protocol = experiment.experiment_assets.detect { |aa| aa.asset_id=protocol.id }.versioned_asset
    assert_equal protocol.version, stored_protocol.version


  end

  test "should update timestamp when associating protocol" do
    login_as(:model_owner)
    experiment=experiments(:metabolomics_experiment)
    timestamp=experiment.updated_at

    protocol = protocols(:protocol_with_all_sysmo_users_policy)
    assert !experiment.protocols.include?(protocol.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>experiment, :experiment_protocol_ids=>[protocol.id], :experiment=>{}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to experiment_path(experiment)
    assert assigns(:experiment)
    updated_experiment=Experiment.find(experiment.id)
    assert updated_experiment.protocols.include?(protocol.latest_version)
    assert_not_equal timestamp, updated_experiment.updated_at

  end


  test "should update timestamp when associating datafile" do
    login_as(:model_owner)
    experiment=experiments(:metabolomics_experiment)
    timestamp=experiment.updated_at

    df = data_files(:downloadable_data_file)
    assert !experiment.data_files.include?(df.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>experiment, :data_file_ids=>["#{df.id},Test data"], :experiment=>{}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to experiment_path(experiment)
    assert assigns(:experiment)
    updated_experiment=Experiment.find(experiment.id)
    assert updated_experiment.data_files.include?(df.latest_version)
    assert_not_equal timestamp, updated_experiment.updated_at
  end

  test "should update timestamp when associating model" do
    login_as(:model_owner)
    experiment=experiments(:metabolomics_experiment)
    timestamp=experiment.updated_at

    model = models(:teusink)
    assert !experiment.models.include?(model.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>experiment, :experiment_model_ids=>[model.id], :experiment=>{}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to experiment_path(experiment)
    assert assigns(:experiment)
    updated_experiment=Experiment.find(experiment.id)
    assert updated_experiment.models.include?(model.latest_version)
    assert_not_equal timestamp, updated_experiment.updated_at
  end

  test "should show item" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success
    assert_not_nil assigns(:experiment)

    assert_select "p#experiment_type", :text=>/Metabalomics/, :count=>1
    assert_select "p#technology_type", :text=>/Gas chromatography/, :count=>1
  end

  test "should not show tagging when not logged in" do
    logout
    public_experiment = Factory(:experimental_experiment, :policy => Factory(:public_policy))
    get :show, :id=>public_experiment
    assert_response :success
    assert_select "div#tags_box", :count=>0
  end

  test "should show svg item" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment), :format=>"svg"
    end

    assert_response :success
    assert @response.body.include?("Generated by Graphviz"), "SVG generation failed, please make you you have graphviz installed, and the 'dot' command is available"
  end

  test "should show modelling experiment" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:modelling_experiment_with_data_and_relationship)
    end

    assert_response :success
    assert_not_nil assigns(:experiment)
    assert_equal assigns(:experiment), experiments(:modelling_experiment_with_data_and_relationship)
  end

  test "should show new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:experiment)
    assert_nil assigns(:experiment).study
  end

  test "should show new with study when id provided" do
    s=studies(:metabolomics_study)
    get :new, :study_id=>s
    assert_response :success
    assert_not_nil assigns(:experiment)
    assert_equal s, assigns(:experiment).study
  end

  test "should show item with no study" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:experiment_with_no_study_or_files)
    end

    assert_response :success
    assert_not_nil assigns(:experiment)
  end

  test "should update with study" do
    login_as(:model_owner)
    a=experiments(:experiment_with_no_study_or_files)
    s=studies(:metabolomics_study)
    assert_difference('ActivityLog.count') do
      put :update, :id=>a, :experiment=>{:study=>s}, :experiment_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to experiment_path(a)
    assert assigns(:experiment)
    assert_not_nil assigns(:experiment).study
    assert_equal s, assigns(:experiment).study
  end

test "should create experimental experiment with or without sample" do
    #THIS TEST MAY BECOME INVALID ONCE IT IS DECIDED HOW ASSAYS LINK TO SAMPLES OR ORGANISMS
    assert_difference('ActivityLog.count') do
      assert_difference("Experiment.count") do
        post :create, :experiment=>{:title=>"test",
                               :technology_type_id=>technology_types(:gas_chromatography).id,
                               :experiment_type_id=>experiment_types(:metabolomics).id,
                               :study_id=>studies(:metabolomics_study).id,
                               :experiment_class=>experiment_classes(:experimental_experiment_class),
                               :owner => Factory(:person)}
      end
    end
    a=assigns(:experiment)
    assert a.samples.empty?


    sample = Factory(:sample)
    assert_difference('ActivityLog.count') do
      assert_difference("Experiment.count") do
        post :create, :experiment=>{:title=>"test",
                               :technology_type_id=>technology_types(:gas_chromatography).id,
                               :experiment_type_id=>experiment_types(:metabolomics).id,
                               :study_id=>studies(:metabolomics_study).id,
                               :experiment_class=>experiment_classes(:experimental_experiment_class),
                               :owner => Factory(:person),
                               :sample_ids=>[sample.id]
        }

      end
    end
    a=assigns(:experiment)
    assert_redirected_to experiment_path(a)
    assert_equal [sample],a.samples
    #assert_equal organisms(:yeast),a.organism
end


  test "should create experimental experiment with/without organisms" do

    assert_difference("Experiment.count") do
      post :create, :experiment=>{:title=>"test",
                             :technology_type_id=>technology_types(:gas_chromatography).id,
                             :experiment_type_id=>experiment_types(:metabolomics).id,
                             :study_id=>studies(:metabolomics_study).id,
                             :experiment_class=>experiment_classes(:experimental_experiment_class),
                             :owner => Factory(:person),
                             :samples => [Factory(:sample)]}
    end

    assert_difference("Experiment.count") do
      post :create, :experiment=>{:title=>"test",
                             :technology_type_id=>technology_types(:gas_chromatography).id,
                             :experiment_type_id=>experiment_types(:metabolomics).id,
                             :study_id=>studies(:metabolomics_study).id,
                             :experiment_class=>experiment_classes(:experimental_experiment_class),
                             :owner => Factory(:person),
                             :samples => [Factory(:sample)]},
           :experiment_organism_ids => [Factory(:organism).id, Factory(:strain).title, Factory(:culture_growth_type).title].to_s
    end
    a=assigns(:experiment)
    assert_redirected_to experiment_path(a)
  end

  test "should create modelling experiment with/without organisms" do

    assert_difference("Experiment.count") do
      post :create, :experiment=>{:title=>"test",
                             :experiment_type_id=>experiment_types(:metabolomics).id,
                             :study_id=>studies(:metabolomics_study).id,
                             :experiment_class=>experiment_classes(:modelling_experiment_class),
                             :owner => Factory(:person)}
    end

    assert_difference("Experiment.count") do
      post :create, :experiment=>{:title=>"test",
                             :experiment_type_id=>experiment_types(:metabolomics).id,
                             :study_id=>studies(:metabolomics_study).id,
                             :experiment_class=>experiment_classes(:modelling_experiment_class),
                             :owner => Factory(:person)},
           :experiment_organism_ids => [Factory(:organism).id, Factory(:strain).title, Factory(:culture_growth_type).title].to_s
    end
    a=assigns(:experiment)
    assert_redirected_to experiment_path(a)
  end

  test "should not create modelling experiment with sample" do
    #FIXME: its allows at the moment due to time constraints before pals meeting, and fixtures and factories need updating. JIRA: SYSMO-734
    assert_no_difference("Experiment.count") do
      post :create, :experiment=>{:title=>"test",
                             :technology_type_id=>technology_types(:gas_chromatography).id,
                             :experiment_type_id=>experiment_types(:metabolomics).id,
                             :study_id=>studies(:metabolomics_study).id,
                             :experiment_class=>experiment_classes(:modelling_experiment_class),
                             :owner => Factory(:person),
                             :sample_ids=>[Factory(:sample).id, Factory(:sample).id]
      }
    end
    
  end

  test "should delete experiment with study" do
    login_as(:model_owner)
    assert_difference('ActivityLog.count') do
      assert_difference('Experiment.count', -1) do
        delete :destroy, :id => experiments(:experiment_with_just_a_study).id
      end
    end

    assert_nil flash[:error]
    assert_redirected_to experiments_path
  end

  test "should not delete experiment when not project member" do
    a = experiments(:experiment_with_just_a_study)
    login_as(:aaron)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "should not delete experiment when not project pal" do
    a = experiments(:experiment_with_just_a_study)
    login_as(:datafile_owner)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "should show edit when not logged in" do
    logout
    a = Factory :experimental_experiment,:contributor=>Factory(:person),:policy=>Factory(:editing_public_policy)
    get :edit,:id=>a
    assert_response :success

    a = Factory :modelling_experiment,:contributor=>Factory(:person),:policy=>Factory(:editing_public_policy)
    get :edit,:id=>a
    assert_response :success
  end

  test "should not edit experiment when not project pal" do
    a = experiments(:experiment_with_just_a_study)
    login_as(:datafile_owner)
    get :edit, :id => a
    assert flash[:error]
    assert_redirected_to a
  end

  test "admin should not edit somebody elses experiment" do
    a = experiments(:experiment_with_just_a_study)
    login_as(:quentin)
    get :edit, :id => a
    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete experiment with data files" do
    login_as(:model_owner)
    a = experiments(:experiment_with_no_study_but_has_some_files)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end
    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "should not delete experiment with model" do
    login_as(:model_owner)
    a = experiments(:experiment_with_a_model)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "should not delete experiment with publication" do
    login_as(:model_owner)
    a = experiments(:experiment_with_a_publication)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "should not delete experiment with protocols" do
    login_as(:model_owner)
    a = experiments(:experiment_with_no_study_but_has_some_protocols)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Experiment.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to experiments_path
  end

  test "get new presents options for class" do
    login_as(:model_owner)
    get :new
    assert_response :success
    assert_select "a[href=?]", new_experiment_path(:class=>:experimental), :count=>1
    assert_select "a", :text=>/An experimental experiment/i, :count=>1
    assert_select "a[href=?]", new_experiment_path(:class=>:modelling), :count=>1
    assert_select "a", :text=>/A modelling analysis/i, :count=>1
  end

  test "get new with class doesnt present options for class" do
    login_as(:model_owner)
    get :new, :class=>"experimental"
    assert_response :success
    assert_select "a[href=?]", new_experiment_path(:class=>:experimental), :count=>0
    assert_select "a", :text=>/An experimental experiment/i, :count=>0
    assert_select "a[href=?]", new_experiment_path(:class=>:modelling), :count=>0
    assert_select "a", :text=>/A modelling analysis/i, :count=>0

    get :new, :class=>"modelling"
    assert_response :success
    assert_select "a[href=?]", new_experiment_path(:class=>:experimental), :count=>0
    assert_select "a", :text=>/An experimental experiment/i, :count=>0
    assert_select "a[href=?]", new_experiment_path(:class=>:modelling), :count=>0
    assert_select "a", :text=>/A modelling analysis/i, :count=>0
  end

  test "data file list should only include those from project" do
    login_as(:model_owner)
    get :new, :class=>"experimental"
    assert_response :success
    assert_select "select#possible_data_files" do
      assert_select "option", :text=>/Sysmo Data File/, :count=>1
      assert_select "option", :text=>/Myexperiment Data File/, :count=>0
    end
  end

  test "download link for protocol in tab has version" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=download_protocol_path(protocols(:my_first_protocol))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "show link for protocol in tab has version" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=protocol_path(protocols(:my_first_protocol))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "edit link for protocol in tabs" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=edit_protocol_path(protocols(:my_first_protocol))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "download link for data_file in tabs" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=download_data_file_path(data_files(:picture))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "show link for data_file in tabs" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=data_file_path(data_files(:picture))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "edit link for data_file in tabs" do
    login_as(:owner_of_my_first_protocol)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=edit_data_file_path(data_files(:picture))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "links have nofollow in protocol tabs" do
    login_as(:owner_of_my_first_protocol)
    protocol_version=protocols(:my_first_protocol)
    protocol_version.description="http://news.bbc.co.uk"
    protocol_version.save!
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]", "nofollow", :text=>/news\.bbc\.co\.uk/, :minimum=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    login_as(:owner_of_my_first_protocol)
    data_file_version=data_files(:picture)
    data_file_version.description="http://news.bbc.co.uk"
    data_file_version.save!
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiments(:metabolomics_experiment)
    end

    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]", "nofollow", :text=>/news\.bbc\.co\.uk/, :minimum=>1
    end
  end


  def test_should_add_nofollow_to_links_in_show_page
    assert_difference('ActivityLog.count') do
      get :show, :id=> experiments(:experiment_with_links_in_description)
    end

    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

    #checks that for an experiment that has 2 protocols and 2 datafiles, of which 1 is public and 1 private - only links to the public protocols & datafiles are show
  def test_authorization_of_protocols_and_datafiles_links
    #sanity check the fixtures are correct
    check_fixtures_for_authorization_of_protocols_and_datafiles_links
    login_as(:model_owner)
    experiment=experiments(:experiment_with_public_and_private_protocols_and_datafiles)
    assert_difference('ActivityLog.count') do
      get :show, :id=>experiment.id
    end

    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3", :text=>"Protocols (1+1)", :count=>1
      assert_select "h3", :text=>"Data Files (1+1)", :count=>1
    end

    assert_select "div.list_item" do
      assert_select "div.list_item_title a[href=?]", protocol_path(protocols(:protocol_with_fully_public_policy)), :text=>"Protocol with fully public policy", :count=>1
      assert_select "div.list_item_actions a[href=?]", protocol_path(protocols(:protocol_with_fully_public_policy)), :count=>1
      assert_select "div.list_item_title a[href=?]", protocol_path(protocols(:protocol_with_private_policy_and_custom_sharing)), :count=>0
      assert_select "div.list_item_actions a[href=?]", protocol_path(protocols(:protocol_with_private_policy_and_custom_sharing)), :count=>0

      assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:downloadable_data_file)), :text=>"Download Only", :count=>1
      assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:downloadable_data_file)), :count=>1
      assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:private_data_file)), :count=>0
      assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:private_data_file)), :count=>0
    end

  end

  test "associated assets aren't lost on failed validation in create" do
    protocol=protocols(:protocol_with_all_sysmo_users_policy)
    model=models(:model_with_links_in_description)
    datafile=data_files(:downloadable_data_file)
    rel=RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference("Experiment.count", "Should not have added experiment because the title is blank") do
        assert_no_difference("ExperimentAsset.count", "Should not have added experiment assets because the experiment validation failed") do
          #title is blank, so should fail validation
          post :create, :experiment=>{
              :title=>"",
              :technology_type_id=>technology_types(:gas_chromatography).id,
              :experiment_type_id=>experiment_types(:metabolomics).id,
              :study_id=>studies(:metabolomics_study).id,
              :experiment_class=>experiment_classes(:modelling_experiment_class)
          },
               :experiment_protocol_ids=>["#{protocol.id}"],
               :experiment_model_ids=>["#{model.id}"],
               :data_file_ids=>["#{datafile.id},#{rel.title}"]
        end
      end
    end


      #since the items are added to the UI by manipulating the DOM with javascript, we can't do assert_select on the HTML elements to check they are there.
      #so instead check for the relevant generated lines of javascript
    assert_select "script", :text=>/protocol_title = '#{protocol.title}'/, :count=>1
    assert_select "script", :text=>/protocol_id = '#{protocol.id}'/, :count=>1
    assert_select "script", :text=>/model_title = '#{model.title}'/, :count=>1
    assert_select "script", :text=>/model_id = '#{model.id}'/, :count=>1
    assert_select "script", :text=>/data_title = '#{datafile.title}'/, :count=>1
    assert_select "script", :text=>/data_file_id = '#{datafile.id}'/, :count=>1
    assert_select "script", :text=>/relationship_type = '#{rel.title}'/, :count=>1
    assert_select "script", :text=>/addDataFile/, :count=>1
    assert_select "script", :text=>/addProtocol/, :count=>1
    assert_select "script", :text=>/addModel/, :count=>1
  end

  test "associated assets aren't lost on failed validation on update" do
    login_as(:model_owner)
    experiment=experiments(:experiment_with_links_in_description)

      #remove any existing associated assets
    experiment.assets.clear
    experiment.save!
    experiment.reload
    assert experiment.protocols.empty?
    assert experiment.models.empty?
    assert experiment.data_files.empty?

    protocol=protocols(:protocol_with_all_sysmo_users_policy)
    model=models(:model_with_links_in_description)
    datafile=data_files(:downloadable_data_file)
    rel=RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference("Experiment.count", "Should not have added experiment because the title is blank") do
        assert_no_difference("ExperimentAsset.count", "Should not have added experiment assets because the experiment validation failed") do
          #title is blank, so should fail validation
          put :update, :id=>experiment, :experiment=>{:title=>"", :experiment_class=>experiment_classes(:modelling_experiment_class)},
              :experiment_protocol_ids=>["#{protocol.id}"],
              :experiment_model_ids=>["#{model.id}"],
              :data_file_ids=>["#{datafile.id},#{rel.title}"]
        end
      end
    end


      #since the items are added to the UI by manipulating the DOM with javascript, we can't do assert_select on the HTML elements to check they are there.
      #so instead check for the relevant generated lines of javascript
    assert_select "script", :text=>/protocol_title = '#{protocol.title}'/, :count=>1
    assert_select "script", :text=>/protocol_id = '#{protocol.id}'/, :count=>1
    assert_select "script", :text=>/model_title = '#{model.title}'/, :count=>1
    assert_select "script", :text=>/model_id = '#{model.id}'/, :count=>1
    assert_select "script", :text=>/data_title = '#{datafile.title}'/, :count=>1
    assert_select "script", :text=>/data_file_id = '#{datafile.id}'/, :count=>1
    assert_select "script", :text=>/relationship_type = '#{rel.title}'/, :count=>1
    assert_select "script", :text=>/addDataFile/, :count=>1
    assert_select "script", :text=>/addProtocol/, :count=>1
    assert_select "script", :text=>/addModel/, :count=>1
  end

  def check_fixtures_for_authorization_of_protocols_and_datafiles_links
    user=users(:model_owner)
    experiment=experiments(:experiment_with_public_and_private_protocols_and_datafiles)
    assert_equal 4, experiment.assets.size
    assert_equal 2, experiment.protocols.size
    assert_equal 2, experiment.data_files.size
    assert experiment.protocols.include?(protocols(:protocol_with_fully_public_policy).find_version(1))
    assert experiment.protocols.include?(protocols(:protocol_with_private_policy_and_custom_sharing).find_version(1))
    assert experiment.data_files.include?(data_files(:downloadable_data_file).find_version(1))
    assert experiment.data_files.include?(data_files(:private_data_file).find_version(1))

    assert protocols(:protocol_with_fully_public_policy).can_view? user
    assert !protocols(:protocol_with_private_policy_and_custom_sharing).can_view?(user)
    assert data_files(:downloadable_data_file).can_view?(user)
    assert !data_files(:private_data_file).can_view?(user)
  end

  test "filtering by study" do
    study=studies(:metabolomics_study)
    get :index, :filter => {:study => study.id}
    assert_response :success
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

  test "filtering by person" do
    person = people(:person_for_model_owner)
    get :index, :filter=>{:person=>person.id}, :page=>"all"
    assert_response :success
    a = experiments(:metabolomics_experiment)
    a2 = experiments(:modelling_experiment_with_data_and_relationship)
    assert_select "div.list_items_container" do
      assert_select "a", :text=>a.title, :count=>1
      assert_select "a", :text=>a2.title, :count=>0
    end
  end

  test 'edit experiment with selected projects scope policy' do
    proj = User.current_user.person.projects.first
    experiment = Factory(:experiment, :contributor => User.current_user.person,
                    :study => Factory(:study, :investigation => Factory(:investigation, :projects => [proj])),
                    :policy => Factory(:policy,
                                       :sharing_scope => Policy::ALL_SYSMO_USERS,
                                       :access_type => Policy::NO_ACCESS,
                                       :permissions => [Factory(:permission, :contributor => proj, :access_type => Policy::EDITING)]))
    get :edit, :id => experiment.id
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do
    login_as(:quentin)
    a = {:title=>"test", :technology_type_id=>technology_types(:gas_chromatography).id, :experiment_type_id=>experiment_types(:metabolomics).id,
         :study_id=>studies(:metabolomics_study).id, :experiment_class=>experiment_classes(:experimental_experiment_class), :sample_ids=>[Factory(:sample).id]}
    assert_difference('ActivityLog.count') do
      assert_difference('Experiment.count') do
        post :create, :experiment => a, :sharing=>{"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::VISIBLE, :sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::ACCESSIBLE}
      end
    end

    experiment=assigns(:experiment)
    assert_redirected_to experiment_path(experiment)
    assert_equal Policy::ALL_SYSMO_USERS, experiment.policy.sharing_scope
    assert_equal Policy::VISIBLE, experiment.policy.access_type
    assert_equal experiment.policy.permissions.count, 1

    experiment.policy.permissions.each do |permission|
      assert_equal permission.contributor_type, 'Project'
      assert experiment.study.investigation.project_ids.include?(permission.contributor_id)
      assert_equal permission.policy_id, experiment.policy_id
      assert_equal permission.access_type, Policy::ACCESSIBLE
    end
  end

  test "should update sharing permissions 'with your project and with all SysMO members'" do
    login_as Factory(:user)
    experiment= Factory(:experiment,
                   :policy => Factory(:private_policy),
                   :contributor => User.current_user.person,
                   :study => (Factory(:study, :investigation => (Factory(:investigation,
                                                                         :projects => [Factory(:project), Factory(:project)])))))

    assert experiment.can_manage?
    assert_equal Policy::PRIVATE, experiment.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, experiment.policy.access_type
    assert experiment.policy.permissions.empty?

    assert_difference('ActivityLog.count') do
      put :update, :id => experiment, :experiment => {}, :sharing => {"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::ACCESSIBLE, :sharing_scope => Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::EDITING}
    end

    experiment.reload
    assert_redirected_to experiment_path(experiment)
    assert_equal Policy::ALL_SYSMO_USERS, experiment.policy.sharing_scope
    assert_equal Policy::ACCESSIBLE, experiment.policy.access_type
    assert_equal 2, experiment.policy.permissions.length

    experiment.policy.permissions.each do |update_permission|
      assert_equal update_permission.contributor_type, 'Project'
      assert experiment.projects.map(&:id).include?(update_permission.contributor_id)
      assert_equal update_permission.policy_id, experiment.policy_id
      assert_equal update_permission.access_type, Policy::EDITING
    end
  end
end
