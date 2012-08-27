require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :all
  
  # ************************************************************************
  # this section tests individual helper methods within Authorization module
  # ************************************************************************
  
  # testing: is_person_in_whitelist?(person_id, whitelist_owner_user_id)


  def test_is_person_in_whitelist__should_yield_true
    res = Authorization.is_person_in_whitelist?(people(:person_for_owner_of_fully_public_policy), users(:owner_of_a_protocol_with_complex_permissions))
    
    assert res, "test person should have been identified as being in the whitelist of test user"
  end
  
  def test_is_person_in_whitelist__should_yield_false
    res = Authorization.is_person_in_whitelist?(people(:random_userless_person), users(:owner_of_a_protocol_with_complex_permissions))
    
    assert !res, "test person should have not been identified as being in the whitelist of test user"
  end

  def test_auth_on_asset_version
    user1 = Factory :user
    user2 = Factory :user
    protocol = Factory :protocol, :contributor=>user1, :policy=>Factory(:private_policy)
    protocol.policy.permissions << Factory(:permission, :policy=>protocol.policy,:contributor=>user2.person,:access_type=>Policy::VISIBLE)
    assert_equal 1,protocol.versions.count
    protocol_v=protocol.versions.first

    assert_equal protocol,protocol_v.parent

    assert protocol.can_manage?(user1)
    assert !protocol.can_manage?(user2)
    assert protocol.can_view?(user2)
    assert !protocol.can_view?(nil)
    assert !protocol.can_download?(user2)
    assert !protocol.can_edit?(user2)

    assert protocol_v.can_manage?(user1)
    assert !protocol_v.can_manage?(user2)
    assert protocol_v.can_view?(user2)
    assert !protocol_v.can_view?(nil)
    assert !protocol_v.can_download?(user2)
    assert !protocol_v.can_edit?(user2)
  end

  # testing: is_person_in_blacklist?(person_id, blacklist_owner_user_id)
  def test_is_person_in_blacklist__should_yield_true
    res = Authorization.is_person_in_blacklist?(people(:person_for_owner_of_my_first_protocol), users(:owner_of_a_protocol_with_complex_permissions))
    
    assert res, "test person should have been identified as being in the blacklist of test user"
  end
  
  def test_is_person_in_blacklist__should_yield_false
    res = Authorization.is_person_in_blacklist?(people(:random_userless_person), users(:owner_of_a_protocol_with_complex_permissions))
    
    assert !res, "test person should have not been identified as being in the blacklist of test user"
  end
  
  
  
  # testing: is_member?(person_id, group_type, group_id)
  # member of any SysMO projects at all? (e.g. a "SysMO user": person who is associated with at least one project / institution ('workgroup'), not just a registered user)
  def test_is_member_associated_with_any_projects_true
    res = people(:random_userless_person).member?
    
    assert res, "person associated with some SysMO projects was thought not to be associated with any"
  end
  
  # member of any SysMO projects at all?
  def test_is_member_associated_with_any_projects_false
    res = people(:person_not_associated_with_any_projects).member?
    
    assert !res, "person not associated with any SysMO projects was thought to be a member of some"
  end
  
  
  # testing: access_type_allows_action?(action, access_type)
  
  def test_access_type_allows_action_no_access
    assert !Authorization.access_type_allows_action?("view", Policy::NO_ACCESS), "'view' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("download", Policy::NO_ACCESS), "'download' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("edit", Policy::NO_ACCESS), "'edit' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("delete", Policy::NO_ACCESS), "'delete' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("manage", Policy::NO_ACCESS), "'manage' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
  end
  
  def test_access_type_allows_action_viewing_only
    assert Authorization.access_type_allows_action?("view", Policy::VISIBLE), "'view' action should have been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Authorization.access_type_allows_action?("download", Policy::VISIBLE), "'download' action should NOT have been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Authorization.access_type_allows_action?("edit", Policy::VISIBLE), "'edit' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Authorization.access_type_allows_action?("delete", Policy::VISIBLE), "'delete' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Authorization.access_type_allows_action?("manage", Policy::VISIBLE), "'manage' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
  end
  
  def test_access_type_allows_action_viewing_and_downloading_only
    assert Authorization.access_type_allows_action?("view", Policy::ACCESSIBLE), "'view' action should have been allowed with access_type set to 'Policy::ACCESSIBLE' (cascading permissions)"
    assert Authorization.access_type_allows_action?("download", Policy::ACCESSIBLE), "'download' action should have been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Authorization.access_type_allows_action?("edit", Policy::ACCESSIBLE), "'edit' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Authorization.access_type_allows_action?("delete", Policy::ACCESSIBLE), "'delete' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Authorization.access_type_allows_action?("manage", Policy::ACCESSIBLE), "'manage' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
  end
  
  def test_access_type_allows_action_editing
    assert Authorization.access_type_allows_action?("view", Policy::EDITING), "'view' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("download", Policy::EDITING), "'download' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("edit", Policy::EDITING), "'edit' action should have been allowed with access_type set to 'Policy::EDITING'"
    assert !Authorization.access_type_allows_action?("delete", Policy::EDITING), "'delete' action should have NOT been allowed with access_type set to 'Policy::EDITING'"
    assert !Authorization.access_type_allows_action?("manage", Policy::EDITING), "'manage' action should have NOT been allowed with access_type set to 'Policy::EDITING'"
  end
  
  def test_access_type_allows_action_managing
    assert Authorization.access_type_allows_action?("view", Policy::MANAGING), "'view' action should have been allowed with access_type set to 'Policy::MANAGING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("download", Policy::MANAGING), "'download' action should have been allowed with access_type set to 'Policy::MANAGING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("edit", Policy::MANAGING), "'edit' action should have been allowed with access_type set to 'Policy::MANAGING'"
    assert Authorization.access_type_allows_action?("delete", Policy::MANAGING), "'delete' action should have been allowed with access_type set to 'Policy::MANAGING'"
    assert Authorization.access_type_allows_action?("manage", Policy::MANAGING), "'manage' action should have been allowed with access_type set to 'Policy::MANAGING'"
  end
  
  
  
  # ****************************************************************************
  # this section tests integration of individual helpers in Authorization module
  # ****************************************************************************
  
  # testing: authorized_by_policy?(policy, thing_asset, action, user_id, user_person_id)
  
  # 'everyone' policy
  def test_authorized_by_policy_fully_public_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), protocols(:protocol_with_fully_public_policy), "download", nil, nil)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow not logged in users to perform 'download' where it should allow even 'edit'"
  end
  
  def test_authorized_by_policy_fully_public_policy_registered_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), protocols(:protocol_with_fully_public_policy), "download", users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow registered user to perform 'download' where it should allow even 'edit'"
  end
  
  def test_authorized_by_policy_fully_public_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), protocols(:protocol_with_fully_public_policy), "download", users(:owner_of_my_first_protocol), users(:owner_of_my_first_protocol).person)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow SysMO user to perform 'download' where it should allow even 'edit'"
  end

  def test_authorized_for_model
    res = temp_authorized_by_policy?(policies(:policy_for_test_with_projects_institutions),models(:teusink),"view",users(:model_owner),people(:person_for_model_owner))
    assert res, "model_owner should be able to view his own model"
  end

  def test_not_authorized_for_model
    res = temp_authorized_by_policy?(policies(:policy_for_test_with_projects_institutions),models(:teusink),"download",users(:quentin),users(:quentin).person)
    assert !res, "Quentin should not be able to download that model"
  end
  
  # 'all SysMO users' policy
  def test_authorized_by_policy_all_sysmo_users_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), protocols(:protocol_with_all_sysmo_users_policy), "download", nil, nil)
    assert !res, "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_all_sysmo_users_policy_registered_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), protocols(:protocol_with_all_sysmo_users_policy), "download", users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert !res, "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' would allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_all_sysmo_users_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), protocols(:protocol_with_all_sysmo_users_policy), "download", users(:owner_of_my_first_protocol), users(:owner_of_my_first_protocol).person)
    assert res, "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' wouldn't allow SysMO user to perform allowed action"
  end
  
  # 'private' policy
  def test_authorized_by_policy_private_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_protocol), protocols(:my_first_protocol), "download", nil, nil)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_private_policy_registered_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_protocol), protocols(:my_first_protocol), "download", users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_private_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_protocol), protocols(:my_first_protocol), "download", users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow SysMO user to perform allowed action"
  end
  
  def test_authorized_by_policy_private_policy_sysmo_user_versioned
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_protocol), protocols(:my_first_protocol).latest_version, "download", users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow SysMO user to perform allowed action"
  end
  
  
  # ****************************************************************************
  # This section is dedicated to test the main method of the module:
  #     is_authorized?(action_name, thing_type, thing, user=nil)
  # ****************************************************************************
  
  # testing combinations of types of input parameters
  def test_is_authorized_for_model
    res = Authorization.is_authorized?("view", "Model", models(:teusink), users(:model_owner))
    assert res, "model_owner should be able to view his own model"
  end

  def test_is_not_authorized_for_model
    res = Authorization.is_authorized?("view", "Model", models(:teusink), users(:quentin))
    assert res, "Quentin should not be able to view the model_owner's model"
  end
  
  # testing that asset owners can delete (plus verifying different options fur submitting the 'thing' and the 'user')
  
  def test_is_authorized_owner_who_is_not_policy_admin_can_delete
    res = Authorization.is_authorized?("delete", nil, protocols(:protocol_with_complex_permissions), users(:owner_of_my_first_protocol))
    assert res, "owner of asset who isn't its policy admin couldn't delete the asset"
  end
  
  # testing whitelist / blacklist
  
  # policy.use_whitelist == true AND test person in the whitelist AND not authorized action --> false (currently "edit" requires more access rights than just being in the whitelist)
  def test_person_in_whitelist_and_use_whitelist_set_to_true_but_not_authorized_action
    temp = protocols(:protocol_with_custom_permissions_policy).policy.use_whitelist
    assert temp, "use_whitelist should have been set to 'true'"
    
    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person, protocols(:protocol_with_custom_permissions_policy).contributor)
    assert temp, "test person should have been in the whitelist of the protocol owner"
    
    temp = (Policy::EDITING > FavouriteGroup::WHITELIST_ACCESS_TYPE)
    assert temp, "editing is now authorized by whitelist access type"
    
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_with_custom_permissions_policy), users(:test_user_only_in_whitelist))
    assert !res, "editing shouldn't have been authorized for a a person in the whitelist - flag to use whitelist was set"
  end
  
  
  # policy.use_whitelist == false AND test person in the whitelist --> false (e.g. permission for whitelist exists, but policy flag isn't set)
  def test_person_in_whitelist_and_allowed_action_but_use_whitelist_set_to_false
    temp = protocols(:my_first_protocol).policy.use_whitelist
    assert !temp, "use_whitelist should have been set to 'false'"
    
    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person, protocols(:my_first_protocol).contributor)
    assert temp, "test person should have been in the whitelist of the protocol owner"
    
    res = Authorization.is_authorized?("download", nil, protocols(:my_first_protocol), users(:test_user_only_in_whitelist))
    assert !res, "download shouldn't have been authorized for a a person in the whitelist - flag to use whitelist wasn't set"
  end
  
  # policy.use_whitelist == false AND test person not in the whitelist --> false
  def test_person_not_in_whitelist_and_allowed_action_and_use_whitelist_set_to_false
    temp = protocols(:my_first_protocol).policy.use_whitelist
    assert !temp, "use_whitelist should have been set to 'false'"
    
    temp = Authorization.is_person_in_whitelist?(users(:registered_user_with_no_projects).person, protocols(:my_first_protocol).contributor)
    assert !temp, "test person shouldn't have been in the whitelist of the protocol owner"
    
    res = Authorization.is_authorized?("download", nil, protocols(:my_first_protocol), users(:registered_user_with_no_projects))
    assert !res, "download shouldn't have been authorized for a a person not in the whitelist - especially when flag to use whitelist wasn't set"
  end
  
  
  
  # policy.use_blacklist == true AND test person not in the blacklist --> true
  def test_person_not_in_blacklist_and_use_blacklist_set_to_true
    temp = protocols(:protocol_with_all_sysmo_users_policy).policy.use_blacklist
    assert temp, "use_blacklist should have been set to 'true'"
    
    temp = people(:person_for_owner_of_my_first_protocol).member?
    assert temp, "test person is associated with some SysMO projects, but was thought not to be associated with any"
    
    temp = Authorization.is_person_in_blacklist?(people(:person_for_owner_of_my_first_protocol), protocols(:protocol_with_all_sysmo_users_policy).contributor)
    assert !temp, "test person shouldn't have been in the blacklist of the protocol owner"

    res = protocols(:protocol_with_all_sysmo_users_policy).can_view? people(:person_for_owner_of_my_first_protocol).user
    assert res, "test user is SysMO user and is not in blacklist - should have been authorized for viewing"
  end
  
  # policy.use_blacklist == false AND test person in the blacklist --> true
  def test_person_in_the_blacklist_but_use_blacklist_set_to_false
    temp = protocols(:protocol_with_complex_permissions).policy.use_blacklist
    assert !temp, "use_blacklist should have been set to 'false'"
    
    temp = Authorization.is_person_in_blacklist?(users(:owner_of_my_first_protocol).person, users(:owner_of_a_protocol_with_complex_permissions))
    assert temp, "test person should have been in the blacklist of the protocol owner"
    
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_complex_permissions), users(:owner_of_my_first_protocol))
    assert res, "view should have been authorized for a a person in the blacklist - flag to use blacklist wasn't set"
  end
  
  # policy.use_blacklist == false AND test person not in the blacklist --> true
  def test_person_not_in_the_blacklist_and_use_blacklist_set_to_false
    temp = protocols(:protocol_with_complex_permissions).policy.use_blacklist
    assert !temp, "use_blacklist should have been set to 'false'"
    
    temp = Authorization.is_person_in_blacklist?(users(:test_user_only_in_whitelist).person, protocols(:protocol_with_complex_permissions).contributor)
    assert !temp, "test person shouldn't have been in the blacklist of the protocol owner"
    
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_complex_permissions), users(:test_user_only_in_whitelist))
    assert res, "view should have been authorized for a a person not in the blacklist - especially when flag to use blacklist wasn't set"
  end
  
  # policy.use_whitelist == true AND policy.use_blacklist == true AND test person in both whitelist and blacklist --> false
  def test_person_in_both_whitelist_and_blacklist
    # this is mainly to test that blacklist takes precedence over the whitelist
    
    temp = protocols(:protocol_with_all_sysmo_users_policy).policy.use_whitelist
    assert temp, "'use_whitelist' flag should have been set to 'true' for this test"
    
    temp = protocols(:protocol_with_all_sysmo_users_policy).policy.use_blacklist
    assert temp, "'use_blacklist' flag should have been set to 'true' for this test"
    
    temp = Authorization.is_person_in_blacklist?(users(:sysmo_user_both_in_blacklist_and_whitelist).person, protocols(:protocol_with_all_sysmo_users_policy).contributor)
    assert temp, "test person should have been in the blacklist of the protocol owner"
    
    temp = Authorization.is_person_in_whitelist?(users(:sysmo_user_both_in_blacklist_and_whitelist).person, protocols(:protocol_with_all_sysmo_users_policy).contributor)
    assert temp, "test person should have been in the whitelist of the protocol owner"
    
    temp = temp_authorized_by_policy?(protocols(:protocol_with_all_sysmo_users_policy).policy, protocols(:protocol_with_all_sysmo_users_policy), "edit",
                                               users(:sysmo_user_both_in_blacklist_and_whitelist), users(:sysmo_user_both_in_blacklist_and_whitelist).person)
    assert temp, "test user is SysMO user and should have been authorized by policy"
    
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_all_sysmo_users_policy), users(:sysmo_user_both_in_blacklist_and_whitelist))
  end
  
  
  # testing individual user permissions

  # check that if the user is in the blacklist/whitelist, individual permissions will be used appropriately
  # (i.e. that blacklist has precedence over individual permissions, but whitelist doesn't -- 
  #  therefore, if someone is in the whitelist, but that wouldn't authorize the action, further checks will be made)
  def test_blacklist_has_precedence_over_individual_permissions
    temp = protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).policy.use_blacklist
    assert temp, "policy for test Protocol should use blacklist"
    

    # verify that test user is in the blacklist
    temp = Authorization.is_person_in_blacklist?(users(:registered_user_with_no_projects).person, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).contributor)
    assert temp, "test person should have been in the blacklist of the protocol owner"
    
    # verify that test user has an individual permission, too
    # (this has to give more access than the general policy settings) 
    permissions = temp_get_person_permissions(users(:registered_user_with_no_projects).person, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).policy)
    assert permissions.length == 1, "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type > protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).policy.access_type, "expected that the permission would give the test user more access than general policy settings"
    
    # verify that individual permission will not be used, because blacklist has precedence
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing), users(:registered_user_with_no_projects))
    assert !res, "test user shouldn't have been allowed to 'download' the Protocol even having the individual permission and use_custom_sharing is set to true - blacklist membership should have had precedence"
    
    # in fact, even 'viewing' allowed by general policy settings shouldn't be allowed because of the blacklist
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing), users(:registered_user_with_no_projects))
    assert !res, "test user shouldn't have been allowed to 'view' the Protocol - blacklist membership should have denied this"
  end
  
  def test_whitelist_doesnt_have_precedence_over_individual_permissions
    temp = protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).policy.use_whitelist
    assert temp, "policy for test Protocol should use whitelist"

    # verify that test user is in the whitelist
    temp = Authorization.is_person_in_whitelist?(users(:owner_of_private_policy_using_custom_sharing).person, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).contributor)
    assert temp, "test person should have been in the whitelist of the protocol owner"
    
    # verify that test user has an individual permission, too
    # (this has to give more access than membership in the whitelist for this test case to make sense:
    #  whitelist has to allow at most to download, but the test individual permission - to edit) 
    permissions = temp_get_person_permissions(users(:owner_of_private_policy_using_custom_sharing).person, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing).policy)
    assert permissions.length == 1, "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type > FavouriteGroup::WHITELIST_ACCESS_TYPE, "expected that the permission would give the test user more access than membership in the whitelist"

    # verify that being in whitelist wouldn't authorize the action
    temp = Authorization.access_type_allows_action?("edit", FavouriteGroup::WHITELIST_ACCESS_TYPE)
    assert !temp, "whitelist solely shouldn't allow 'editing' otherwise this test case doesn't make sense"
    
    # verify that individual permission will be used, because whitelist doesn't have precedence
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_that_uses_whitelist_blacklist_and_custom_sharing), users(:owner_of_private_policy_using_custom_sharing))
    assert res, "test user should have been allowed to 'edit' the Protocol having the individual permission and use_custom_sharing is set to true - whitelist membership should not have had precedence"
  end

  # policy.use_blacklist == true AND test person in the blacklist --> false
  def test_person_in_blacklist_and_use_blacklist_set_to_true
    temp = protocols(:protocol_with_all_sysmo_users_policy).policy.use_blacklist
    assert temp, "use_blacklist should have been set to 'true'"

    temp = people(:person_for_sysmo_user_in_blacklist).member?
    assert temp, "test person is associated with some SysMO projects, but was thought not to be associated with any"

    temp = Authorization.is_person_in_blacklist?(people(:person_for_sysmo_user_in_blacklist), protocols(:protocol_with_all_sysmo_users_policy).contributor)
    assert temp, "test person should have been in the blacklist of the protocol owner"

    # "view" is used instead of "show" because that's a precondition for Authorization.access_type_allows_action?() helper - it assumes that
    # Authorization.categorize_action() was called on the action before - and that yields "view" for "show" action
    temp = temp_authorized_by_policy?(protocols(:protocol_with_all_sysmo_users_policy).policy, protocols(:protocol_with_all_sysmo_users_policy), "view",
                                               people(:person_for_sysmo_user_in_blacklist).user, people(:person_for_sysmo_user_in_blacklist))
    assert temp, "test user is SysMO user and should have been authorized by policy"

    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_all_sysmo_users_policy), people(:person_for_sysmo_user_in_blacklist).user)
    assert !res, "test user is SysMO user, but is also in blacklist - should not have been authorized for viewing"
  end

  # policy.use_whitelist == true AND test person in the whitelist AND allowed action --> true
  def test_person_in_whitelist_and_use_whitelist_set_to_true
    temp = protocols(:protocol_with_custom_permissions_policy).policy.use_whitelist
    assert temp, "use_whitelist should have been set to 'true'"

    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person, protocols(:protocol_with_custom_permissions_policy).contributor)
    assert temp, "test person should have been in the whitelist of the protocol owner"

    res = Authorization.is_authorized?("download", nil, protocols(:protocol_with_custom_permissions_policy), users(:test_user_only_in_whitelist))
    assert res, "download should have been authorized for a a person in the whitelist - flag to use whitelist was set"
  end
  
  
  # testing favourite groups
  
  # someone with individual permission and in favourite group (more access than in individual permission) - permission in favourite group should never be used in such case
  def test_fav_group_permissions_dont_get_used_if_individual_permissions_exist
    temp = protocols(:protocol_with_download_for_all_sysmo_users_policy).policy.use_whitelist
    assert !temp, "policy for test Protocol shouldn't use whitelist"
    
    temp = protocols(:protocol_with_download_for_all_sysmo_users_policy).policy.use_blacklist
    assert !temp, "policy for test Protocol shouldn't use blacklist"
    
    # download is allowed for all sysmo users..
    temp = temp_authorized_by_policy?(protocols(:protocol_with_download_for_all_sysmo_users_policy).policy, protocols(:protocol_with_download_for_all_sysmo_users_policy), "download",
                                               users(:sysmo_user_who_wants_to_access_different_things), users(:sysmo_user_who_wants_to_access_different_things).person)
    assert temp, "policy of the test Protocol should have allowed 'download' of that asset"
    
    # ..but editing is not allowed
    temp = temp_authorized_by_policy?(protocols(:protocol_with_download_for_all_sysmo_users_policy).policy, protocols(:protocol_with_download_for_all_sysmo_users_policy), "edit",
                                               users(:sysmo_user_who_wants_to_access_different_things), users(:sysmo_user_who_wants_to_access_different_things).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'edit' of that asset"

    # verify that permissions for the user exist, but don't give enough access rights..
    permissions = temp_get_person_permissions(users(:sysmo_user_who_wants_to_access_different_things).person, protocols(:protocol_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::VISIBLE, "expected that the permission would give the test user viewing access to the test Protocol, but no access for editing"
    
    # ..check that sharing with favourite group gives more access to this person..
    permissions = temp_get_person_access_rights_from_favourite_group_permissions(users(:sysmo_user_who_wants_to_access_different_things).person, protocols(:protocol_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::EDITING, "expected that the permission would give the test user access to the test Protocol for editing"
    
    # ..and now verify that permissions from favourite groups won't get used, because individual permissions have precedence
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_with_download_for_all_sysmo_users_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert !res, "test user should not have been allowed to 'edit' the Protocol - individual permission should have denied the action"
    
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_with_download_for_all_sysmo_users_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert !res, "test user should not have been allowed to 'download' the Protocol - individual permission should have denied the action (these limit it to less that public access)"
    
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_with_download_for_all_sysmo_users_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'view' the Protocol - this is what individual permissions only allow"
  end
  
  # someone with no individual permissions - hence the actual permission from being a member in a favourite group is used
  def test_fav_groups_permissions
    temp = protocols(:protocol_with_download_for_all_sysmo_users_policy).policy.use_whitelist
    assert !temp, "policy for test Protocol shouldn't use whitelist"
    
    temp = protocols(:protocol_with_download_for_all_sysmo_users_policy).policy.use_blacklist
    assert !temp, "policy for test Protocol shouldn't use blacklist"
    
    # editing is not allowed by policy (only download is)
    temp = temp_authorized_by_policy?(protocols(:protocol_with_download_for_all_sysmo_users_policy).policy, protocols(:protocol_with_download_for_all_sysmo_users_policy), "edit",
                                               users(:owner_of_my_first_protocol), users(:owner_of_my_first_protocol).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'edit' of that asset"

    # verify that no individual permissions for the user exist..
    permissions = temp_get_person_permissions(users(:owner_of_my_first_protocol).person, protocols(:protocol_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 0, "expected to have no permission in that policy for the test person, not #{permissions.length}"
    
    # ..check that sharing with favourite group gives some access to this person..
    permissions = temp_get_person_access_rights_from_favourite_group_permissions(users(:owner_of_my_first_protocol).person, protocols(:protocol_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::EDITING, "expected that the permission would give the test user access to the test Protocol for editing"
    
    # ..and now verify that permissions from favourite groups are actually used
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_with_download_for_all_sysmo_users_policy), users(:owner_of_my_first_protocol))
    assert res, "test user should have been allowed to 'edit' the Protocol - because of favourite group membership and permissions"
  end
  

  # testing general policy settings
  
  def test_general_policy_settings_action_allowed
    # check that no permissions will be used..
    temp = protocols(:protocol_with_fully_public_policy).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_with_fully_public_policy).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"
    
    group_permissions = temp_get_group_permissions(protocols(:protocol_with_fully_public_policy).policy)
    assert group_permissions.empty?, 'there should be no group permissions for this policy'

    person_permissions = temp_get_person_permissions(users(:owner_of_my_first_protocol).person, protocols(:protocol_with_fully_public_policy).policy)
    assert person_permissions.empty?, 'there should be no person permissions for this policy'

    # ..all flags are checked to 'false'; only policy settings will be used
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_with_fully_public_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'edit' the Protocol - it uses fully public policy"
  end
  
  def test_general_policy_settings_action_not_authorized
    # check that no permissions will be used..
    temp = protocols(:protocol_with_public_download_and_no_custom_sharing).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_with_public_download_and_no_custom_sharing).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"

    group_permissions = temp_get_group_permissions(protocols(:protocol_with_public_download_and_no_custom_sharing).policy)
    assert group_permissions.empty?, 'there should be no group permissions for this policy'

    person_permissions = temp_get_person_permissions(users(:owner_of_my_first_protocol).person, protocols(:protocol_with_public_download_and_no_custom_sharing).policy)
    assert person_permissions.empty?, 'there should be no person permissions for this policy'

    # ..all flags are checked to 'false'; only policy settings will be used
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_with_public_download_and_no_custom_sharing), users(:sysmo_user_who_wants_to_access_different_things))
    assert !res, "test user shouldn't have been allowed to 'edit' the Protocol - policy only allows downloading"
    
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_with_public_download_and_no_custom_sharing), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'download' the Protocol - policy allows downloading"
  end
  
  
  # testing group permissions
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'WorkGroup';
  def test_group_permissions_will_allow_action
    # check that policy flags are set correctly
    temp = protocols(:protocol_for_test_with_workgroups).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_for_test_with_workgroups).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"
    
    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(protocols(:protocol_for_test_with_workgroups).policy, protocols(:protocol_for_test_with_workgroups), "download",
                                               users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = temp_get_group_permissions(protocols(:protocol_for_test_with_workgroups).policy)
    assert permissions.length == 1, "expected to have one permission for workgroups in that policy, not #{permissions.length}"
    assert permissions[0].contributor_type == "WorkGroup", "expected to have permission for 'WorkGroup'"
    assert permissions[0].access_type == Policy::ACCESSIBLE, "expected that the permission would give the test user download access to the test Protocol"
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_for_test_with_workgroups), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the Protocol - because of group permission"
  end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'WorkGroup'; "use_custom_permissions" flat set to 'false'
=begin
  def test_group_permissions_could_allow_action_but_use_custom_sharing_set_to_false
    # check that policy flags are set correctly
    temp = protocols(:protocol_for_test_with_workgroups_no_custom_sharing).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_for_test_with_workgroups_no_custom_sharing).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(protocols(:protocol_for_test_with_workgroups_no_custom_sharing).policy, protocols(:protocol_for_test_with_workgroups_no_custom_sharing), "download",
                                               users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = temp_get_group_permissions(protocols(:protocol_for_test_with_workgroups_no_custom_sharing).policy)
    assert permissions.length == 1, "expected to have one permission for workgroups in that policy, not #{permissions.length}"
    assert permissions[0].contributor_type == "WorkGroup", "expected to have permission for 'WorkGroup'"
    assert permissions[0].access_type == Policy::ACCESSIBLE, "expected that the permission would give the test user download access to the test Protocol"
    
    # verify that group permissions won't be applied and access is still prohibited
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_for_test_with_workgroups_no_custom_sharing), users(:owner_of_fully_public_policy))
    assert !res, "test user shouldn't have been allowed to 'download' the Protocol - because group permission shouldn't be applied when 'use_custom_sharing' is set to 'false'"
    
    # viewing should still be allowed by the policy
    res = Authorization.is_authorized?("view", nil, protocols(:protocol_for_test_with_workgroups_no_custom_sharing), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'view' the Protocol - because of policy settings"
  end
=end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Project'
  def test_group_permissions_shared_with_project
    # check that policy flags are set correctly
    temp = protocols(:protocol_for_test_with_projects_institutions).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_for_test_with_projects_institutions).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(protocols(:protocol_for_test_with_projects_institutions).policy, protocols(:protocol_for_test_with_projects_institutions), "edit",
                                               users(:owner_of_download_for_all_sysmo_users_policy), users(:owner_of_download_for_all_sysmo_users_policy).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'edit' of that asset"
    
    # verify that group permissions exist
    permissions = temp_get_group_permissions(protocols(:protocol_for_test_with_projects_institutions).policy)
    assert permissions.length == 2, "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == "Project"
      perm = permissions[0]
    elsif permissions[1].contributor_type == "Project"
      perm = permissions[1]
    else
      perm = nil
    end
    assert !perm.nil?, "couldn't find correct permission for the test"
    assert perm.access_type == Policy::EDITING, "expected that the permission would give the test user edit access to the test Protocol"
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("edit", nil, protocols(:protocol_for_test_with_projects_institutions), users(:owner_of_download_for_all_sysmo_users_policy))
    assert res, "test user should have been allowed to 'download' the Protocol - because of group permission: shared with test user's project"
  end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Institution'
  def test_group_permissions_shared_with_institution
    # check that policy flags are set correctly
    temp = protocols(:protocol_for_test_with_projects_institutions).policy.use_whitelist
    assert !temp, "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = protocols(:protocol_for_test_with_projects_institutions).policy.use_blacklist
    assert !temp, "'use_blacklist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(protocols(:protocol_for_test_with_projects_institutions).policy, protocols(:protocol_for_test_with_projects_institutions), "download",
                                               users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !temp, "policy of the test Protocol shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = temp_get_group_permissions(protocols(:protocol_for_test_with_projects_institutions).policy)
    assert permissions.length == 2, "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == "Institution"
      perm = permissions[0]
    elsif permissions[1].contributor_type == "Institution"
      perm = permissions[1]
    else
      perm = nil
    end
    assert !perm.nil?, "couldn't find correct permission for the test"
    assert perm.access_type == Policy::ACCESSIBLE, "expected that the permission would give the test user download access to the test Protocol"
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("download", nil, protocols(:protocol_for_test_with_projects_institutions), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the Protocol - because of group permission: shared with test user's institution"
  end

  def test_downloadable_data_file
    data_file=data_files(:downloadable_data_file)
    res=Authorization.is_authorized?("download",DataFile,data_file,users(:aaron))
    assert res,"should be downloadable by all"
    assert data_file.can_download?(users(:aaron))
    res=Authorization.is_authorized?("edit",DataFile,data_file,users(:aaron))
    assert !res,"should not be editable"
    assert !data_file.can_edit?(users(:aaron))
  end

  def test_editable_data_file
    data_file=data_files(:editable_data_file)
    res=Authorization.is_authorized?("download",DataFile,data_file,users(:aaron))
    assert res,"should be downloadable by all"
    assert data_file.can_download?(users(:aaron))
    res=Authorization.is_authorized?("edit",DataFile,data_file,users(:aaron))
    assert res,"should be editable"
    assert data_file.can_edit?(users(:aaron))
  end

  def test_downloadable_protocol
    protocol=protocols(:downloadable_protocol)
    res=Authorization.is_authorized?("download",Protocol,protocol,users(:aaron))
    assert res,"Should be able to download"
    assert protocol.can_download?(users(:aaron))

    assert protocol.can_view? users(:aaron)

    res=Authorization.is_authorized?("edit",Protocol,protocol,users(:aaron))
    assert !res,"Should not be able to edit"
    assert !protocol.can_edit?(users(:aaron))
  end

  def test_editable_protocol
    protocol=protocols(:editable_protocol)
    res=Authorization.is_authorized?("download",Protocol,protocol,users(:aaron))
    assert res,"Should be able to download"
    assert protocol.can_download?(users(:aaron))

    assert protocol.can_view?(users(:aaron))

    res=Authorization.is_authorized?("edit",Protocol,protocol,users(:aaron))
    assert res,"Should be able to edit"
    assert protocol.can_edit?(users(:aaron))
  end

  def test_asset_with_no_contributor
    protocol=protocols(:protocol_with_no_contributor) #should be editable to all those that are members of a project
    user=users(:pal_user)
    assert Authorization.is_authorized?("view",Protocol,protocol,user), "The protocol with no contributor should be viewable to the pal"
    assert Authorization.is_authorized?("edit",Protocol,protocol,user), "The protocol with no contributor should be editable to the pal"
    assert Authorization.is_authorized?("download",Protocol,protocol,user), "The protocol with no contributor should be downloadable to the pal"
    assert !Authorization.is_authorized?("manage",Protocol,protocol,user), "The protocol with no contributor should not be managable to the pal"
  end

  def test_asset_with_no_contributor_with_managing_permission
    protocol=protocols(:protocol_with_no_contributor) #should be editable to all those that are members of a project
    user=users(:pal_user)
    assert !Authorization.is_authorized?("manage",Protocol,protocol,user), "The should not be managable to the pal"
    #now add the managable
    p=Permission.new(:contributor=>user.person,:policy=>protocol.policy,:access_type=>Policy::MANAGING)
    protocol.policy.permissions << p
    protocol.policy
    protocol.policy.save!
    
    assert protocol.can_manage?(user), "The protocol should now be managable to the pal"
  end

  def test_anyone_can_do_anything_for_policy_free_items
    item = Factory :project
    User.current_user = Factory :user
    actions.each {|a| assert item.can_perform? a}
    assert item.can_edit?
    assert item.can_view?
    assert item.can_download?
    assert item.can_delete?
    assert item.can_manage?
  end

  def test_contributor_can_do_anything
    item = Factory :protocol, :policy => Factory(:private_policy)
    User.current_user = item.contributor
    actions.each {|a| assert item.can_perform? a}
    assert item.can_edit?
    assert item.can_view?
    assert item.can_download?
    assert item.can_delete?
    assert item.can_manage?
  end

  def test_private_item_does_not_allow_anything
    item = Factory :protocol, :policy => Factory(:private_policy)
    User.current_user = Factory :user
    actions.each {|a| assert !item.can_perform?(a)}
    assert !item.can_edit?
    assert !item.can_view?
    assert !item.can_download?
    assert !item.can_delete?
    assert !item.can_manage?
  end

  def test_permission_has_precendence_over_policy
    person = Factory :person
    assert_equal 1,person.projects.count,"Should only be in 1 project"
    project = person.projects.first
    user=person.user
    item = Factory :protocol, :policy=>Factory(:all_sysmo_viewable_policy)
    User.with_current_user user do
      assert item.can_view?
    end
    item.policy.permissions << Factory(:permission, :contributor => project, :access_type => Policy::NO_ACCESS, :policy => item.policy)
                
    User.with_current_user user do
      assert !item.can_view?
    end

    item = Factory :protocol, :policy=>Factory(:private_policy)
    User.with_current_user user do
      assert !item.can_view?
    end
    item.policy.permissions << Factory(:permission, :contributor => project, :access_type => Policy::VISIBLE, :policy => item.policy)
    User.with_current_user user do
      assert item.can_view?
    end
  end

  def test_permissions
    User.current_user = Factory :user
    access_levels = {Policy::MANAGING => actions, 
                     Policy::NO_ACCESS => [],
                     Policy::VISIBLE => [:view],
                     Policy::ACCESSIBLE => [:view, :download],
                     Policy::EDITING => [:view, :download, :edit]}
    access_levels.each do |access, allowed|
      policy = Factory :private_policy
      policy.permissions << Factory(:permission, :contributor => User.current_user.person, :access_type => access, :policy => policy)
      item = Factory :protocol, :policy => policy
      actions.each {|action| assert_equal allowed.include?(action), item.can_perform?(action), "User should #{allowed.include?(action) ? nil : "not "}be allowed to #{action}"}
      assert_equal item.can_view?, allowed.include?(:view)
      assert_equal item.can_edit?, allowed.include?(:edit)
      assert_equal item.can_download?, allowed.include?(:download)
      assert_equal item.can_delete?, allowed.include?(:delete)
      assert_equal item.can_manage?, allowed.include?(:manage)
    end
  end


  test 'creator should edit the asset, but can not manage' do
    item = Factory :protocol, :policy => Factory(:private_policy)
    person = Factory :person
    Factory :assets_creator, :asset => item, :creator => person

    User.current_user = person.user

    assert item.can_edit?
    assert item.can_view?
    assert item.can_download?
    assert !item.can_delete?
    assert !item.can_manage?
  end

  test "gatekeeper can publish items inside their project, only if they can manage it as well" do
    gatekeeper = Factory(:person, :roles => ['gatekeeper'])
    datafile = Factory(:data_file, :projects => gatekeeper.projects)

    #adding manage right for gatekeeper
    User.with_current_user datafile.contributor do
      policy  = Factory(:policy)
      policy.permissions = [Factory(:permission, :contributor => gatekeeper, :access_type => Policy::MANAGING)]
      datafile.policy = policy
      datafile.save
    end

    ability = Ability.new(gatekeeper.user)
    assert ability.can? :publish, datafile

    User.with_current_user gatekeeper.user do
      assert datafile.can_manage?
      assert datafile.can_publish?
    end
  end

  test "gatekeeper can not publish items inside their project, if they can not manage it" do
      gatekeeper = Factory(:person, :roles => ['gatekeeper'])
      datafile = Factory(:data_file, :projects => gatekeeper.projects)

      ability = Ability.new(gatekeeper.user)
      assert ability.cannot? :publish, datafile

      User.with_current_user gatekeeper.user do
        assert !datafile.can_manage?
        assert !datafile.can_publish?
      end
    end


  test "gatekeeper can not publish items outside their project" do
    gatekeeper = Factory(:person, :roles => ['gatekeeper'])
    datafile = Factory(:data_file)

    ability = Ability.new(gatekeeper.user)
    assert ability.cannot? :publish, datafile

    User.with_current_user gatekeeper.user do
      assert !datafile.can_publish?
    end
  end

  test "asset manager can manage the items inside their projects, except the entirely private items" do
    asset_manager = Factory(:person, :roles => ['asset_manager'])
    datafile1 = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:publicly_viewable_policy))
    datafile2 = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:private_policy))

    ability = Ability.new(asset_manager.user)

    assert ability.can? :manage_asset, datafile1
    assert ability.cannot? :manage_asset, datafile2
    assert ability.cannot? :manage, datafile2

    User.with_current_user asset_manager.user do
      assert datafile1.can_manage?
      assert !datafile2.can_manage?
    end
  end

  test "asset manager can not manage the items outside their projects" do
    asset_manager = Factory(:person, :roles => ['asset_manager'])
    datafile = Factory(:data_file)
    assert (asset_manager.projects & datafile.projects).empty?

    ability = Ability.new(asset_manager.user)

    assert ability.cannot? :manage_asset, datafile
    assert ability.cannot? :manage, datafile

    User.with_current_user asset_manager.user do
      assert !datafile.can_manage?
    end
  end

  test "asset manager can manage items inside their projects, the items have private sharing scope, but have permissions" do
    asset_manager = Factory(:person, :roles => ['asset_manager'])
    datafile = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:private_policy, :permissions => [Factory(:permission, :access_type => Policy::VISIBLE)]))

    assert !(asset_manager.projects & datafile.projects).empty?

    ability = Ability.new(asset_manager.user)

    assert ability.can? :manage_asset, datafile

    User.with_current_user asset_manager.user do
      assert datafile.can_manage?
    end
  end

  test "asset manager can manage the items inside their projects, but can not publish the items, which hasn't been set to published" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)

    asset_manager = Factory(:asset_manager, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    gatekeeper = Factory(:gatekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    datafile = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:all_sysmo_viewable_policy))

    User.with_current_user asset_manager.user do
      assert datafile.can_manage?
      assert !datafile.can_publish?

      ability = Ability.new(asset_manager.user)
      assert asset_manager.is_asset_manager?
      assert ability.can? :manage_asset, datafile
      assert ability.cannot? :publish, datafile
     end
  end

  test "a person who is not an asset manager, who can manage the item, should not be able to publish the items, which hasn't been set to published" do
     person_can_manage = Factory(:person)
     gatekeeper = Factory(:gatekeeper)
     datafile = Factory(:data_file, :projects => gatekeeper.projects, :policy => Factory(:policy))
     permission = Factory(:permission, :contributor => person_can_manage, :access_type => Policy::MANAGING, :policy => datafile.policy)

     User.with_current_user person_can_manage.user do
       assert datafile.can_manage?
       assert !datafile.can_publish?

       ability = Ability.new(person_can_manage.user)
       assert person_can_manage.roles.empty?
       assert ability.cannot? :manage_asset, datafile
       assert ability.cannot? :manage, datafile
       assert ability.cannot? :publish, datafile
     end
  end

  test "gatekeeper should not be able to manage the item" do
    gatekeeper = Factory(:gatekeeper)
     datafile = Factory(:data_file, :projects => gatekeeper.projects, :policy => Factory(:all_sysmo_viewable_policy))

     User.with_current_user gatekeeper.user do
       assert !datafile.can_manage?

       ability = Ability.new(gatekeeper.user)
       assert gatekeeper.is_gatekeeper?
       assert ability.cannot? :publish, datafile
       assert ability.cannot? :manage_asset, datafile
       assert ability.cannot? :manage, datafile
     end
  end

  test "manager should be able to publish if the projects have no gatekeepers" do
     person_can_manage = Factory(:person)
     datafile = Factory(:data_file, :projects => person_can_manage.projects, :policy => Factory(:policy))
     permission = Factory(:permission, :contributor => person_can_manage, :access_type => Policy::MANAGING, :policy => datafile.policy)


     User.with_current_user person_can_manage.user do
       assert datafile.gatekeepers.empty?
       assert datafile.can_manage?
       assert datafile.can_publish?
     end
  end

  test "should handle different types of contributor of resource (Person, User)" do
    asset_manager = Factory(:asset_manager)

    policy = Factory(:private_policy)
    permission = Factory(:permission, :contributor => Factory(:person), :access_type => 1)
    policy.permissions = [permission]

    #resources are not entirely private
    datafile = Factory(:data_file, :projects => asset_manager.projects, :policy => policy)
    investigation = Factory(:investigation, :contributor => Factory(:person), :projects => asset_manager.projects, :policy => policy)

    User.with_current_user asset_manager.user do
      assert datafile.can_manage?
      assert investigation.can_manage?
    end
  end

  test "can_publish for new asset" do
    #gatekeeper can publish
    gatekeeper = Factory(:gatekeeper)
    User.with_current_user gatekeeper.user do
      specimen = Specimen.new(:title => 'test1', :strain => strains(:yeast1), :lab_internal_number => '1234', :projects => gatekeeper.projects, :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
      assert specimen.can_publish?
      assert specimen.save
    end

    #contributor can not publish if projects associated with asset have gatekeepers
    User.with_current_user Factory(:user) do
      specimen = Specimen.new(:title => 'test2', :strain => strains(:yeast1), :lab_internal_number => '1234', :projects => gatekeeper.projects, :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
      assert !specimen.gatekeepers.empty?
      assert !specimen.can_publish?
      assert specimen.save
    end

    #contributor can publish if projects associated with asset have no gatekeepers
    User.with_current_user Factory(:user) do
      specimen = Specimen.new(:title => 'test3', :strain => strains(:yeast1), :lab_internal_number => '1234', :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
      assert specimen.gatekeepers.empty?
      assert specimen.can_publish?
      assert specimen.save
    end
  end

  test "can_publish when updating asset" do
    #gatekeeper can publish
    gatekeeper = Factory(:gatekeeper)
    User.with_current_user gatekeeper.user do
      specimen = Factory(:specimen, :projects => gatekeeper.projects, :contributor => gatekeeper)
      specimen.policy.sharing_scope = Policy::EVERYONE
      assert specimen.can_publish?
      assert specimen.save
    end

    work_group = Factory(:work_group, :project => gatekeeper.projects.first)
    contributor = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    #contributor can not publish if projects associated with asset have gatekeepers
    User.with_current_user contributor.user do
      specimen = Factory(:specimen, :projects => gatekeeper.projects, :contributor => contributor)
      specimen.policy.sharing_scope = Policy::EVERYONE
      assert !specimen.can_publish?
      assert specimen.save
    end

    #contributor can publish if projects associated with asset have no gatekeepers
    User.with_current_user contributor.user do
      specimen = Factory(:specimen, :contributor => contributor)
      specimen.policy.sharing_scope = Policy::EVERYONE
      assert specimen.can_publish?
      assert specimen.save
    end

    #contributor can publish if asset was already published
    specimen = specimens(:public_specimen)
    User.with_current_user specimen.contributor do
      assert !specimen.gatekeepers.empty?
      assert !specimen.contributor.person.is_gatekeeper?
      assert_equal Policy::EVERYONE, specimen.policy.sharing_scope
      specimen.policy.sharing_scope = Policy::EVERYONE
      assert specimen.can_publish?
      assert specimen.save
    end
  end

  test 'unauthorized_change_to_autosave?' do
    df = Factory(:data_file)
    assert Policy::PRIVATE, df.policy.sharing_scope
    df.policy.sharing_scope = Policy::ALL_SYSMO_USERS
    assert !df.save
    df.reload
    assert_equal Policy::PRIVATE, df.policy.sharing_scope

    disable_authorization_checks do
      df.policy.sharing_scope = Policy::ALL_SYSMO_USERS
      assert df.save
      df.reload
      assert_equal Policy::ALL_SYSMO_USERS, df.policy.sharing_scope
    end
  end

  test 'disable authorization check for publishing_auth' do
    df = Factory(:data_file)
    assert_equal Policy::PRIVATE, df.policy.sharing_scope
    user = Factory(:user)
    User.with_current_user user do
      assert !df.can_publish?
    end

    disable_authorization_checks do
      df.policy.sharing_scope = Policy::EVERYONE
      assert df.save
      df.reload
      assert_equal Policy::EVERYONE, df.policy.sharing_scope
    end
  end

  private 

  def actions
    [:view, :edit, :download, :delete, :manage]
  end

  #To save me re-writing lots of tests. Code copied from authorization.rb
  #Mimics how authorized_by_policy method used to work, but with my changes.
  def temp_authorized_by_policy?(policy, thing, action, user, not_used_2)
    is_authorized = false
    
    # == BASIC POLICY
    # 1. Check the user's "scope" level, to match the sharing scopes defined in policy.
    # 2. If they're in "scope", check the action they're trying to perform is allowed by the access_type    
    scope = nil
    if user.nil?
      scope = Policy::EVERYONE
    else
      if thing.contributor == user
        scope = Policy::PRIVATE
        return true #contributor is always authorized 
        # have to do this because of inconsistancies with access_type that mess up later on
        # (4 = can manage, 0 = can manage... if contributor) ???
      elsif thing.is_downloadable? and thing.creators.include?(user.person) and access_type_allows_action?(action, Policy::EDITING)
        scope = Policy::PRIVATE
        return true
      else
        if user.person && user.person.projects.empty?
          scope = Policy::EVERYONE
        else
          scope = Policy::ALL_SYSMO_USERS
        end
      end
    end
    
    # Check the user is "in scope" and also is performing an action allowed under the given access type
    is_authorized = is_authorized || (scope <= policy.sharing_scope && 
                                      Authorization.access_type_allows_action?(action, policy.access_type))
  end
  
  def temp_get_group_permissions(policy)
    policy.permissions.select {|p| ["WorkGroup","Project","Institution"].include?(p.contributor_type)}
  end

  def temp_get_person_permissions(person, policy)
    policy.permissions.select {|p| p.contributor == person}
  end

  def temp_get_person_access_rights_from_favourite_group_permissions(person, policy)
    favourite_group_ids = policy.permissions.select {|p| p.contributor_type == "FavouriteGroup"}.collect {|p| p.contributor_id}
    #Use favourite_group_membership in place of permission. It has access_type so duck typing will save us.
    person.favourite_group_memberships.select {|x| favourite_group_ids.include?(x.favourite_group_id)}
  end


end
