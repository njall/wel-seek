ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'test_benchmark'
require 'rest_test_cases'
require 'ruby-prof'
require 'factory_girl'
require 'webmock/test_unit'
require 'action_view/test_case'

Factory.find_definitions #It looks like requiring factory_girl _should_ do this automatically, but it doesn't seem to work

Factory.class_eval do
  def self.create_with_privileged_mode *args
    disable_authorization_checks {create_without_privileged_mode *args}
  end

  def self.build_with_privileged_mode *args
    disable_authorization_checks {build_without_privileged_mode *args}
  end

  class_alias_method_chain :create, :privileged_mode
  class_alias_method_chain :build, :privileged_mode
end

Kernel.class_eval do
  def as_virtualliver
    vl = Seek::Config.is_virtualliver
    Seek::Config.is_virtualliver=true
    yield
    Seek::Config.is_virtualliver=vl
  end

  def with_auth_lookup_enabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=true
    yield
    Seek::Config.auth_lookup_enabled=val
  end

  def with_auth_lookup_disabled
    val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=false
    yield
    Seek::Config.auth_lookup_enabled=val
  end
end

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  set_fixture_class :protocol_versions=>Protocol::Version
  set_fixture_class :model_versions=>Model::Version
  set_fixture_class :data_file_versions=>DataFile::Version

  # Add more helper methods to be used by all tests here...

  #profiling

  def start_profiling
    RubyProf.start
  end

  def stop_profiling prefix="profile"
    results = RubyProf.stop

    File.open "#{Rails.root}/tmp/#{prefix}-graph.html", 'w' do |file|
      RubyProf::GraphHtmlPrinter.new(results).print(file)
    end
    File.open "#{Rails.root}/tmp/#{prefix}-flat.txt", 'w' do |file|
      RubyProf::FlatPrinter.new(results).print(file)
    end
  end

  ## stuff for mocking

  def mock_remote_file path,route
    stub_request(:get, route).to_return(:body => File.new(path), :status => 200, :headers=>{'Content-Type' => 'image/png'})
    stub_request(:head, route)
  end

  #mocks the contents of a http response with contents stored in a file
  # path - the http path to be mocked
  # mock_file - the name of the file that resides in test/fixtures/files/mocking and contains the contents of the response
  def mock_response_contents path,mock_file
    contents_path = File.join(Rails.root,"test","fixtures","files","mocking",mock_file)
    xml=File.open(contents_path,"r").read
    stub_request(:get,path).to_return(:status=>200,:body=>xml)
    path
  end
  
end
