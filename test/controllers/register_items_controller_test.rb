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
