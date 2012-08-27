require 'test_helper'

class AssetsHelperTest < ActionView::TestCase

  fixtures :models

  def setup
    User.destroy_all
    assert_blank User.all
    @user = Factory :user
    @project = Factory :project
    @assets = create_a_bunch_of_assets
  end

  def test_asset_version_links
    User.with_current_user Factory(:admin).user do
      model = models(:teusink)
      model_versions = model.versions
      assert_equal 2, model_versions.count
      model_version_links = asset_version_links model_versions
      assert_equal 2, model_version_links.count
      link1 = link_to('Teusink', "/models/#{model.id}" + "?version=1", {:target => '_blank'})
      link2 = link_to('Teusink', "/models/#{model.id}" + "?version=2", {:target => '_blank'})
      assert model_version_links.include?link1
      assert model_version_links.include?link2
    end
  end

  test "authorised assets" do
    with_auth_lookup_disabled do
      check_expected_authorised
    end
  end

  test "authorised assets with lookup" do
    with_auth_lookup_enabled do

      assert_not_equal Protocol.count,Protocol.lookup_count_for_user(@user)
      assert !Protocol.lookup_table_consistent?(@user.id)

      #check_expected_authorised

      update_lookup_tables

      assert_equal DataFile.count,DataFile.lookup_count_for_user(@user.id)
      assert_equal Protocol.count,Protocol.lookup_count_for_user(@user.id)
      assert_equal Protocol.count,Protocol.lookup_count_for_user(@user)
      assert Protocol.lookup_table_consistent?(@user.id)
      assert Protocol.lookup_table_consistent?(nil)

      check_expected_authorised
    end
  end

  def check_expected_authorised
    User.current_user = @user
    authorised = authorised_assets Protocol
    assert_equal 4,authorised.count
    assert_equal ["A","B","D","E"],authorised.collect{|a| a.title}.sort

    authorised = authorised_assets Protocol,@project
    assert_equal 1,authorised.count
    assert_equal "A",authorised.first.title

    authorised = authorised_assets Protocol,@user.person.projects
    assert_equal 1,authorised.count
    assert_equal "E",authorised.first.title

    authorised = authorised_assets Protocol,nil,"manage"
    assert_equal 3,authorised.count
    assert_equal ["A","B","D"],authorised.collect{|a| a.title}.sort

    User.current_user = nil
    authorised = authorised_assets Protocol
    assert_equal 3,authorised.count
    assert_equal ["A","D","E"],authorised.collect{|a| a.title}.sort

    User.current_user = Factory(:user)
    authorised = authorised_assets DataFile,nil,"download"
    assert_equal 2,authorised.count
    assert_equal ["A","B"],authorised.collect{|a| a.title}.sort

    authorised = authorised_assets DataFile,@project,"download"
    assert_equal 1,authorised.count
    assert_equal ["B"],authorised.collect{|a| a.title}

    User.current_user = nil
    authorised = authorised_assets DataFile
    assert_equal 2,authorised.count
    assert_equal ["A","B"],authorised.collect{|a| a.title}.sort
  end

  private

  def update_lookup_tables
    User.all.push(nil).each do |u|
      @assets.each{|a| a.update_lookup_table(u)}
    end

  end

  def create_a_bunch_of_assets
    disable_authorization_checks do
      Protocol.destroy_all
      DataFile.destroy_all
    end
    assert_blank Protocol.all
    assert_blank DataFile.all
    assets = []
    assets << Factory(:protocol, :title=>"A",:policy=>Factory(:public_policy),:projects=>[@project])
    assets << Factory(:protocol, :title=>"B",:contributor=>@user,:policy=>Factory(:private_policy))
    assets << Factory(:protocol, :title=>"C",:policy=>Factory(:private_policy))
    assets << Factory(:protocol, :title=>"D",:contributor=>@user,:policy=>Factory(:publicly_viewable_policy))
    assets << Factory(:protocol, :title=>"E",:policy=>Factory(:publicly_viewable_policy),:projects=>@user.person.projects)

    assets << Factory(:data_file,:title=>"A",:contributor=>@user,:policy=>Factory(:downloadable_public_policy))
    assets << Factory(:data_file,:title=>"B",:policy=>Factory(:downloadable_public_policy),:projects=>[@project,Factory(:project)])
    assets
  end
end