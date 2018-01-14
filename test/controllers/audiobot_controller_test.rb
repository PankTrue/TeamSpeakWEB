require 'test_helper'

class AudiobotControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get audiobot_new_url
    assert_response :success
  end

  test "should get create" do
    get audiobot_create_url
    assert_response :success
  end

  test "should get edit" do
    get audiobot_edit_url
    assert_response :success
  end

  test "should get destroy" do
    get audiobot_destroy_url
    assert_response :success
  end

end
