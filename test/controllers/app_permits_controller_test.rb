require "test_helper"

class AppPermitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @app_permit = app_permits(:one)
  end

  test "should get index" do
    get app_permits_url, as: :json
    assert_response :success
  end

  test "should create app_permit" do
    assert_difference("AppPermit.count") do
      post app_permits_url, params: { app_permit: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show app_permit" do
    get app_permit_url(@app_permit), as: :json
    assert_response :success
  end

  test "should update app_permit" do
    patch app_permit_url(@app_permit), params: { app_permit: {  } }, as: :json
    assert_response :success
  end

  test "should destroy app_permit" do
    assert_difference("AppPermit.count", -1) do
      delete app_permit_url(@app_permit), as: :json
    end

    assert_response :no_content
  end
end
