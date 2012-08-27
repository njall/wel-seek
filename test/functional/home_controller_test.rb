require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include HomeHelper

  test "test should be accessible to seek even if not logged in" do
    get :index
    assert_response :success
  end

  test "test title" do
    login_as(:quentin)
    get :index
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end

  test "correct response to unknown action" do
    login_as(:quentin)
    assert_raises ActionController::UnknownAction do
      get :sdjgsdfjg
    end
  end

  test "should get feedback form" do
    login_as(:quentin)
    get :feedback
    assert_response :success
  end  

  test "admin link not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>0
  end

  test "admin tab visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>1
  end

  test "Protocol tab should be capitalized" do
    login_as(:quentin)
    get :index
    if Seek::Config.is_virtualliver
      assert_select "div.section>li>a[href=?]","/protocols",:text=>"Protocols",:count=>1
    else
      assert_select "ul.tabnav>li>a[href=?]","/protocols",:text=>"Protocols",:count=>1
    end

  end

  test "Protocol upload option should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "select#new_resource_type",:count=>1 do
      assert_select "option[value=?]","protocol",:text=>"Protocol"
    end
  end

  test "hidden items do not appear in recent items" do
    model = Factory :model, :policy => Factory(:private_policy), :title => "A title"

    login_as(:quentin)
    get :index

    #difficult to use assert_select, because of the way the tabbernav tabs are constructed with javascript onLoad
    assert !@response.body.include?(model.title)
  end

  test 'root should route to sign_up when no user, otherwise to home' do
    User.find(:all).each do |u|
      u.delete
    end
    get :index
    assert_redirected_to :controller => 'users', :action => 'new'

    Factory(:user)
    get :index
    assert_response :success
  end

  test 'should hide the forum tab for unlogin user' do
    logout
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>0
  end

  test "should hide forum tab for logged in user" do
    #this test may break if we re-enable forums - which is currently under question. If it does and we have re-enabled just change :count=>1
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>0
  end

  test "should display home description" do
    Seek::Config.home_description="Blah blah blah - http://www.google.com"
    logout

    get :index
    assert_response :success

    assert_select "div.top_home_panel", :text=>/Blah blah blah/, :count=>1
    assert_select "div.top_home_panel a[href=?]", "http://www.google.com", :count=>1

  end

  test "should turn on/off project news and community news" do
    #turn on
    Seek::Config.project_news_enabled=true
    Seek::Config.community_news_enabled=true

    get :index
    assert_response :success

    assert_select "div.heading", :text=>/Community News/, :count=>1
    assert_select "div.heading", :text=>"#{Seek::Config.project_name} News", :count=>1

    #turn off
    Seek::Config.project_news_enabled=false
    Seek::Config.community_news_enabled=false


    get :index
    assert_response :success

    assert_select "div[class='yui-u first home_panel'][style='display:none']", :count => 1
    assert_select "div[class='yui-u home_panel'][style='display:none']", :count => 1
  end

  test "feed reader should handle feed title as subtitle" do
    xml = %!<?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en"><link rel="alternate" type="text/html" href="http://www.sysmo-db.org/news_feed.xml" /><atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" type="application/atom+xml" href="http://feeds.feedburner.com/sysmo-db/ALIS" /><subtitle type="html">Latest news</subtitle><updated>1970-01-01T00:00:00+00:00</updated><atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" type="application/rss+xml" href="http://feeds.feedburner.com/sysmo-db/ALIS" /><feedburner:info xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" uri="sysmo-db/alis" /><atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="hub" href="http://pubsubhubbub.appspot.com/" /><entry><title type="text">Semi-Bad News</title><link rel="alternate" type="text/html" href="http://www.sysmo-db.org/node/50" /><author><name>sowen</name></author><updated>2011-10-21T11:36:33-07:00</updated><id>50 at http://www.sysmo-db.org</id><content type="html">&lt;p&gt;There is a 30 minute maximum delay before feedburner updates.&lt;br /&gt;
      But we can live with that, and its possible to ping it if we need it to update sooner.&lt;/p&gt;</content></entry><entry><title type="text">Good News</title><link rel="alternate" type="text/html" href="http://www.sysmo-db.org/node/49" /><author><name>sowen</name></author><updated>2011-10-21T11:30:44-07:00</updated><id>49 at http://www.sysmo-db.org</id><content type="html">&lt;p&gt;Sysmo-DB news feed now working correctly and working in SEEK&lt;/p&gt;</content></entry><entry><title type="text">Some more news</title><link rel="alternate" type="text/html" href="http://www.sysmo-db.org/node/47" /><author><name>sowen</name></author><updated>2011-10-21T08:45:08-07:00</updated><id>47 at http://www.sysmo-db.org</id><content type="html">&lt;p&gt;This is some more exiting news.&lt;/p&gt;</content></entry><entry><title type="text">Some news</title><link rel="alternate" type="text/html" href="http://www.sysmo-db.org/node/46" /><author><name>sowen</name></author><updated>2011-10-21T08:44:42-07:00</updated><id>46 at http://www.sysmo-db.org</id><content type="html">&lt;p&gt;Here is some news&lt;/p&gt;</content></entry></feed>!

    stub_request(:get,"http://feed.rss").to_return(:status=>200,:body=>xml)
    Seek::Config.project_news_enabled=true
    Seek::Config.project_news_feed_urls = "http://feed.rss"
    Seek::Config.project_news_number_of_entries = "5"

    get :index

    assert_response :success

    assert_select "li.homepanel_item" do
      assert_select "div.feedinfo",:text=>/Latest news/,:count=>4
    end
  end

  test "should handle index html" do
    assert_routing("/",{:controller=>"home",:action=>"index"})
    assert_recognizes({:controller=>"home",:action=>"index"},"/index.html")
    assert_recognizes({:controller=>"home",:action=>"index"},"/index")
  end

  test "should show the content of project news and community news with the configurable number of entries" do
    sbml = mock_response_contents "http://sbml.atom.feed","sbml_atom.xml"
    bbc = mock_response_contents "http://bbc.atom.feed","bbc_atom.xml"
    guardian = mock_response_contents "http://guardian.atom.feed","guardian_atom.xml"
    #project news
    Seek::Config.project_news_enabled=true
    Seek::Config.project_news_feed_urls = "#{bbc}, #{sbml}"
    Seek::Config.project_news_number_of_entries = "5"

    #community news
    Seek::Config.community_news_enabled=true
    Seek::Config.community_news_feed_urls = "#{guardian}"
    Seek::Config.community_news_number_of_entries = "7"

    login_as(:aaron)
    get :index
    assert_response :success

    assert_select 'div#project_news ul>li', 5
    assert_select 'div#community_news ul>li', 7

    logout
    get :index
    assert_response :success

    assert_select 'div#project_news ul>li', 5
    assert_select 'div#community_news ul>li', 7
  end

  test 'should show recently added and downloaded items with the filter can_view?' do
    login_as(:aaron)
    #recently added
    recently_added_item_logs =  recently_added_item_logs(1.year.ago, 10)
    recently_added_item_logs.each do |added_item_log|
      assert added_item_log.activity_loggable.can_view?
    end
    #recently downloaded
    recently_downloaded_item_logs =  recently_downloaded_item_logs(1.year.ago, 10)
    recently_downloaded_item_logs.each do |downloaded_item_log|
      assert downloaded_item_log.activity_loggable.can_view?
    end

    get :index
    assert_response :success

    assert_select 'div#recently_added ul>li', recently_added_item_logs.count
    assert_select 'div#recently_downloaded ul>li', recently_downloaded_item_logs.count

    logout
    #recently uploaded
    recently_added_item_logs =  recently_added_item_logs(1.year.ago, 10)
    recently_added_item_logs.each do |added_item_log|
      assert added_item_log.activity_loggable.can_view?
    end
    #recently downloaded
    recently_downloaded_item_logs =  recently_downloaded_item_logs(1.year.ago, 10)
    recently_downloaded_item_logs.each do |downloaded_item_log|
      assert downloaded_item_log.activity_loggable.can_view?
    end

    get :index
    assert_response :success

    assert_select 'div#recently_added ul>li', recently_added_item_logs.count
    assert_select 'div#recently_downloaded ul>li', recently_downloaded_item_logs.count
  end

  test "recently added should include data_file" do
    login_as(:aaron)

    df = Factory :data_file, :title=>"A new data file", :contributor=>User.current_user.person
    assert_difference "ActivityLog.count" do
      log = Factory :activity_log, :activity_loggable=>df, :controller_name=>"data_files", :culprit=>User.current_user
    end


    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",data_file_path(df),:text=>/A new data file/
  end

  test "recently added should include presentations" do
    login_as(:aaron)

    presentation = Factory :presentation, :title=>"A new presentation", :contributor=>User.current_user.person
    log = Factory :activity_log, :activity_loggable=>presentation, :controller_name=>"presentations", :culprit=>User.current_user

    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",presentation_path(presentation),:text=>/A new presentation/
  end

  test "should show headline announcement" do
    login_as :aaron
    ann=Factory :headline_announcement

    get :index
    assert_response :success
    assert_select "p.headline_announcement" do

    end

    #now expire it
    ann.expires_at=1.day.ago
    ann.save!
    get :index
    assert_response :success
    assert_select "p.headline_announcement",:count=>0
  end
  
end
