require 'test_helper'
class ActivityLogTest < ActiveSupport::TestCase

  test "duplicates" do
    df = Factory :data_file
    protocol = Factory :protocol

    df_log_1 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:controller_name=>"data_files",:created_at=>2.hour.ago
    df_log_2 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:controller_name=>"data_files",:created_at=>1.hour.ago
    df_log_3 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:controller_name=>"data_files",:created_at=>1.minute.ago
    df_log_4 = Factory :activity_log,:activity_loggable=>df,:controller_name=>"data_files",:action=>"download"
    df_log_5 = Factory :activity_log,:activity_loggable=>df,:controller_name=>"data_files",:action=>"download"

    protocol_log_1 = Factory :activity_log,:activity_loggable=>protocol,:controller_name=>"protocols",:action=>"create",:created_at=>2.hour.ago
    protocol_log_2 = Factory :activity_log,:activity_loggable=>protocol,:controller_name=>"protocols",:action=>"create",:created_at=>1.hour.ago
    protocol_log_3 = Factory :activity_log,:activity_loggable=>protocol,:controller_name=>"protocols",:action=>"create",:created_at=>2.minute.ago
    protocol_log_4 = Factory :activity_log,:activity_loggable=>protocol,:controller_name=>"protocols",:action=>"show"
    protocol_log_5 = Factory :activity_log,:activity_loggable=>protocol,:controller_name=>"protocols",:action=>"show"

    assert_equal 2,ActivityLog.duplicates("create").length
    assert_equal 1,ActivityLog.duplicates("download").length
    assert_equal 1,ActivityLog.duplicates("show").length
  end

  test "remove duplicates" do
    df = Factory :data_file
    protocol = Factory :protocol
    
    df_log_1 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:created_at=>2.hour.ago
    df_log_2 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:created_at=>1.hour.ago
    df_log_3 = Factory :activity_log,:activity_loggable=>df,:action=>"create",:created_at=>1.minute.ago
    df_log_4 = Factory :activity_log,:activity_loggable=>df,:action=>"download"
    df_log_5 = Factory :activity_log,:activity_loggable=>df,:action=>"download"

    protocol_log_1 = Factory :activity_log,:activity_loggable=>protocol,:action=>"create",:created_at=>2.hour.ago
    protocol_log_2 = Factory :activity_log,:activity_loggable=>protocol,:action=>"create",:created_at=>1.hour.ago
    protocol_log_3 = Factory :activity_log,:activity_loggable=>protocol,:action=>"create",:created_at=>2.minute.ago
    protocol_log_4 = Factory :activity_log,:activity_loggable=>protocol,:action=>"show"
    protocol_log_5 = Factory :activity_log,:activity_loggable=>protocol,:action=>"show"

    assert_difference("ActivityLog.count",-4) do
      ActivityLog.remove_duplicate_creates
    end

    all=ActivityLog.all
    assert all.include?(df_log_1)
    assert all.include?(df_log_4)
    assert all.include?(df_log_5)
    assert !all.include?(df_log_2)
    assert !all.include?(df_log_3)
    
    all=ActivityLog.all
    assert all.include?(protocol_log_1)
    assert all.include?(protocol_log_4)
    assert all.include?(protocol_log_5)
    assert !all.include?(protocol_log_2)
    assert !all.include?(protocol_log_3)
    
  end

end