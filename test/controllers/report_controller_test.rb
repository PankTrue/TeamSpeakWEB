require 'test_helper'

class ReportControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get report_new_url
    assert_response :success
  end

  test "should get create" do
    get report_create_url
    assert_response :success
  end

  test "should get edit" do
    get report_edit_url
    assert_response :success
  end

  test "should get update" do
    get report_update_url
    assert_response :success
  end

  test "should get destroy" do
    get report_destroy_url
    assert_response :success
  end

end
