require "test_helper"

class PermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @permission = permissions(:one)
  end

  test "should get index" do
    get permissions_url, as: :json
    assert_response :success
  end

  test "should create permission" do
    assert_difference("Permission.count") do
      post permissions_url, params: { permission: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show permission" do
    get permission_url(@permission), as: :json
    assert_response :success
  end

  test "should update permission" do
    patch permission_url(@permission), params: { permission: {  } }, as: :json
    assert_response :success
  end

  test "should destroy permission" do
    assert_difference("Permission.count", -1) do
      delete permission_url(@permission), as: :json
    end

    assert_response :no_content
  end
end
