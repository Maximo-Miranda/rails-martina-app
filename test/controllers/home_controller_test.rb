require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed_user)
  end

  test "should get index" do
    sign_in @user
    get dashboard_url
    assert_response :success
  end
end
