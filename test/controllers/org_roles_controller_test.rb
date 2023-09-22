require "test_helper"

class OrgRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org_role = org_roles(:one)
  end

  test "should get index" do
    get org_roles_url, as: :json
    assert_response :success
  end

  test "should create org_role" do
    assert_difference("OrgRole.count") do
      post org_roles_url, params: { org_role: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show org_role" do
    get org_role_url(@org_role), as: :json
    assert_response :success
  end

  test "should update org_role" do
    patch org_role_url(@org_role), params: { org_role: {  } }, as: :json
    assert_response :success
  end

  test "should destroy org_role" do
    assert_difference("OrgRole.count", -1) do
      delete org_role_url(@org_role), as: :json
    end

    assert_response :no_content
  end
end
