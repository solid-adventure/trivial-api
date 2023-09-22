require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
  end

  test "should get index" do
    get organizations_url, as: :json
    assert_response :success
  end

  test "should create organization" do
    assert_difference("Organization.count") do
      post organizations_url, params: { organization: { billing_email: @organization.billing_email, name: @organization.name, token: @organization.token } }, as: :json
    end

    assert_response :created
  end

  test "should show organization" do
    get organization_url(@organization), as: :json
    assert_response :success
  end

  test "should update organization" do
    patch organization_url(@organization), params: { organization: { billing_email: @organization.billing_email, name: @organization.name, token: @organization.token } }, as: :json
    assert_response :success
  end

  test "should destroy organization" do
    assert_difference("Organization.count", -1) do
      delete organization_url(@organization), as: :json
    end

    assert_response :no_content
  end
end
