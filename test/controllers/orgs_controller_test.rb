require "test_helper"

class OrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = orgs(:one)
  end

  test "should get index" do
    get orgs_url, as: :json
    assert_response :success
  end

  test "should create org" do
    assert_difference("Org.count") do
      post orgs_url, params: { org: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show org" do
    get org_url(@org), as: :json
    assert_response :success
  end

  test "should update org" do
    patch org_url(@org), params: { org: {  } }, as: :json
    assert_response :success
  end

  test "should destroy org" do
    assert_difference("Org.count", -1) do
      delete org_url(@org), as: :json
    end

    assert_response :no_content
  end
end
