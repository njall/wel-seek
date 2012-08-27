require 'test_helper'
#Authorization tests that are specific to public access
class AnonymousAuthorizationTest < ActiveSupport::TestCase
  
  fixtures :all

  test "anonymous can view access and edit public protocol" do
    protocol=protocols(:protocol_with_fully_public_policy)

    assert_equal Policy::EVERYONE,protocol.policy.sharing_scope
    assert_equal Policy::EDITING,protocol.policy.access_type

    assert Authorization.is_authorized? "view",nil,protocol,nil
    assert Authorization.is_authorized? "edit",nil,protocol,nil
    assert Authorization.is_authorized? "download",nil,protocol,nil
    assert !Authorization.is_authorized?("manage",nil,protocol,nil)

    assert protocol.can_view?
    assert protocol.can_edit?
    assert protocol.can_download?
    assert !protocol.can_manage?
  end

  test "anonymous cannot view access or edit non public protocol" do
    protocol=protocols(:protocol_with_download_for_all_sysmo_users_policy)

    assert_equal Policy::ALL_SYSMO_USERS,protocol.policy.sharing_scope
    assert_equal Policy::ACCESSIBLE,protocol.policy.access_type

    assert !Authorization.is_authorized?("view",nil,protocol,nil)
    assert !Authorization.is_authorized?("edit",nil,protocol,nil)
    assert !Authorization.is_authorized?("download",nil,protocol,nil)
    assert !Authorization.is_authorized?("manage",nil,protocol,nil)

    assert !protocol.can_view?
    assert !protocol.can_edit?
    assert !protocol.can_download?
    assert !protocol.can_manage?
  end

  test "anonymous can view but not edit or access publically viewable protocol" do
    User.current_user = nil
    protocol = Factory :protocol, :policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)

    assert protocol.can_view?
    assert !protocol.can_edit?
    assert !protocol.can_download?
    assert !protocol.can_manage?
  end

  test "anonymous can view and download but not edit publically viewable protocol" do
    User.current_user = nil
    protocol=Factory :protocol, :policy => Factory(:policy, :sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE)

    assert protocol.can_view?
    assert protocol.can_download?
    assert !protocol.can_edit?
    assert !protocol.can_manage?
  end



  test "anonymous user allowed to perform an action" do
    # it doesn't matter for this test case if any permissions exist for the policy -
    # these can't affect anonymous user; hence can only check the final result of authorization
    protocol=protocols(:protocol_with_fully_public_policy)
    # verify that the policy really provides access to anonymous users
    temp = protocol.policy.sharing_scope
    temp2 = protocol.policy.access_type
    assert temp == Policy::EVERYONE && temp2 > Policy::NO_ACCESS, "policy should provide some access for anonymous users for this test"

    res = Authorization.is_authorized?("edit", nil, protocol, nil)
    assert res, "anonymous user should have been allowed to 'edit' the Protocol - it uses fully public policy"
  end

  def test_anonymous_user_not_authorized_to_perform_an_action
    # it doesn't matter for this test case if any permissions exist for the policy -
    # these can't affect anonymous user; hence can only check the final result of authorization

    # verify that the policy really provides access to anonymous users
    temp = protocols(:protocol_with_public_download_and_no_custom_sharing).policy.sharing_scope
    assert temp < Policy::EVERYONE, "policy should not include anonymous users into the sharing scope"

    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_public_download_and_no_custom_sharing), nil)
    assert !res, "anonymous user shouldn't have been allowed to 'view' the Protocol - policy authorizes only registered users"
  end


end