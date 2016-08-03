require 'test_helper'

class CabinetControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get cabinet_home_url
    assert_response :success
  end

end
