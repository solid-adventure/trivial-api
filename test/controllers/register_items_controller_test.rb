# test/controllers/register_items_controller_test.rb
require 'test_helper'

class RegisterItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @register = registers(:one)
    @user = users(:admin)

    @register_item_params = {
      unique_key: '271828',
      description: 'Sample Item',
      register_id: @register.id,
      amount: 3.14,
      units: 'USD',
      originated_at: Time.now,
      income_account: "carrier_fees",
      warehouse: "new_york",
      channel: "wholesale",
      invalid_meta: "invalid_value"
    }

    @auth_headers = @user.create_new_auth_token
    @auth_headers["uid"] = @user.uid
  end

  test "should create single register item" do
    assert_difference('RegisterItem.count') do
      post register_items_url,
        params: {
          unique_key: "ABC123",
          description: "Test Item",
          register_id: @register.id,
          amount: 100,
          units: 'USD',
          originated_at: Time.current
        },
        headers: @auth_headers,
        as: :json
    end

    assert_response :success
    response_item = JSON.parse(response.body)
    assert_equal "ABC123", response_item["unique_key"]
    assert_equal "Test Item", response_item["description"]
  end

  test "should handle invalid single item creation" do
    post register_items_url,
      params: {
        unique_key: nil,
        description: "Test Item",
        register_id: @register.id,
        units: 'USD',
        amount: 100
      },
      headers: @auth_headers,
      as: :json

    assert_response :unprocessable_entity
    error_response = JSON.parse(response.body)
    assert_equal error_response["unique_key"], ["has already been taken"]
  end

  test "should create register item with correct meta attributes" do
    assert_difference('RegisterItem.count') do
      post register_items_url, params: @register_item_params, headers: @auth_headers, as: :json
    end
    assert_response :created
    register_item = RegisterItem.last

    meta_array = (0..9).map { |i| "meta#{i}" }
    @register.meta.each do |column, label|
      assert_equal @register_item_params[label.to_sym], register_item[column] # i.e income_account == meta0
      meta_array.delete(column)
    end

    meta_array.each do |col|
      assert_nil register_item[col]
    end
  end

  test "should reject creation when user is not authorized" do
    # Setup an unauthorized user's headers
    unauthorized_headers = { 'Authorization' => 'Bearer unauthorized_token' }

    post register_items_url,
      params: {
        unique_key: "ABC123",
        description: "Test Item",
        register_id: @register.id
      },
      headers: unauthorized_headers,
      as: :json

    assert_response :unauthorized
    error_response = JSON.parse(response.body)
  end

  test "should reject creation when user logged in does not have access to register" do
    post register_items_url,
      params: {
        unique_key: "ABC123",
        description: "Test Item",
        register_id: 3, # register_id is not associated with the user
        units: 'USD',
        amount: 100
      },
      headers: @auth_headers,
      as: :json

    assert_response :unauthorized
    error_response = JSON.parse(response.body)
    assert_equal error_response["errors"], ["You are not authorized to access this page."]
  end

  test "should create multiple register items with correct ownership" do
    items_params = [
      {
        unique_key: "ABC123",
        description: "Test Item 1",
        register_id: @register.id,
        amount: 100,
        units: 'USD',
        originated_at: Time.current
      },
      {
        unique_key: "DEF456",
        description: "Test Item 2",
        register_id: @register.id,
        amount: 200,
        units: 'USD',
        originated_at: Time.current
      }
    ]

    assert_difference('RegisterItem.count', 2) do
      post bulk_create_register_items_url,
        params: { register_items: items_params },
        headers: @auth_headers,
        as: :json
    end

    assert_response :created
    response_items = JSON.parse(response.body)
    assert_equal 2, response_items.length

    RegisterItem.where(unique_key: ["ABC123", "DEF456"]).each do |item|
      assert_equal @register.owner_id, item.owner_id
      assert_equal "Organization", item.owner_type
    end
  end

  test "should handle meta params and ownership in bulk creation" do
    @register.update!(meta: {
      "meta0" => "channel",
      "meta1" => "custom_thing"
    })

    items_params = [
      {
        unique_key: "ABC123",
        description: "Test Item 1",
        register_id: @register.id,
        amount: 100,
        units: 'USD',
        channel: "Online",
        custom_thing: "Special"
      },
      {
        unique_key: "DEF456",
        description: "Test Item 2",
        register_id: @register.id,
        amount: 100,
        units: 'USD',
        channel: "Retail",
        custom_thing: "Regular"
      }
    ]

    assert_difference('RegisterItem.count', 2) do
      post bulk_create_register_items_url,
        params: { register_items: items_params },
        headers: @auth_headers,
        as: :json
    end

    assert_response :created
    response_items = JSON.parse(response.body)

    RegisterItem.where(unique_key: ["ABC123", "DEF456"]).each do |item|
      assert_equal @register.owner_id, item.owner_id
      assert_equal "Organization", item.owner_type
      assert item.meta0.in?(["Online", "Retail"])
      assert item.meta1.in?(["Special", "Regular"])
    end
  end

  test "should rollback ownership and meta if any item is invalid" do
    items_params = [
      {
        unique_key: "ABC123",
        description: "Test Item 1",
        register_id: @register.id,
        amount: 100,
        units: 'USD'
      },
      {
        unique_key: "ABC123",  # invalid
        description: "Test Item 2",
        register_id: @register.id,
        amount: 100,
        units: 'USD'
      }
    ]

    assert_no_difference(['RegisterItem.count']) do
      post bulk_create_register_items_url,
        params: { register_items: items_params },
        headers: @auth_headers,
        as: :json
    end
    assert_response :unprocessable_entity
    assert_equal JSON.parse(response.body)["errors"], ["Unique key has already been taken"]
    assert_not RegisterItem.exists?(unique_key: "ABC123")
  end

  test "should rollback if any item has invalid ownership" do
    items_params = [
      {
        unique_key: "ABC123",
        description: "Test Item 1",
        register_id: @register.id,
        amount: 100,
        units: 'USD'
      },
      {
        unique_key: "DEF456",
        description: "Test Item 2",
        register_id: 3, # invalid
        amount: 100,
        units: 'USD'
      }
    ]

    assert_no_difference(['RegisterItem.count']) do
      post bulk_create_register_items_url,
        params: { register_items: items_params },
        headers: @auth_headers,
        as: :json
    end
    assert_response :unauthorized
    assert_not RegisterItem.exists?(unique_key: "ABC123")
    assert_not RegisterItem.exists?(unique_key: "DEF456")
  end

  test 'correctly aliases meta-columns for items from differing registers but overlapping aliases' do
    get register_items_url, headers: @auth_headers, as: :json
    data = JSON.parse(response.body)["register_items"]
    data.each do |item|
      ri = RegisterItem.find(item["id"])
      meta = Register.where(id: item["register_id"]).pick(:meta)
      meta.each do |column, label|
        assert_equal ri[column], item[label]
      end
    end
  end
end
