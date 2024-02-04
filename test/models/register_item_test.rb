require "test_helper"

class RegisterItemTest < ActiveSupport::TestCase

  test "can lookup by meta fields labels" do
    ri = register_items(:one)
    register = registers(:one)
    assert_equal "income_account", register.meta["meta0"]
    assert_equal "pasta", ri.meta0
    assert_equal "pasta", ri.income_account
  end

  test "register item gets meta fields by name" do
    ri = RegisterItem.new(
      register_id: 1,
      amount: 1.00,
      description: "First transaction",
      income_account: "music",
      owner: User.first,
      unique_key: "1234"
    )
    assert ri.save
    assert_equal "music", ri.income_account
  end

  test "register item gets meta fields by name with create" do
    ri = RegisterItem.create(
      register_id: 1,
      amount: 1.00,
      description: "First transaction",
      income_account: "music",
      owner: User.first,
      unique_key: "1234"
    )
    assert ri.save
    assert_equal "music", ri.income_account
  end

  test "meta fields are non-sequential" do
    ri = RegisterItem.create(
      register_id: 1,
      amount: 1.00,
      description: "First transaction",
      income_account: "music",
      warehouse: "san francisco",
      channel: "retail",
      owner: User.first,
      unique_key: "1234"
    )
    assert ri.save
    ri.reload
    assert_equal "music", ri.income_account
    assert_equal "san francisco", ri.warehouse
    assert_equal "retail", ri.channel
  end

  test "sanitizes meta field names" do
    assert_equal "income_account", RegisterItem.sanitize("income_account")
    assert_equal "income_account", RegisterItem.sanitize("Income Account")
    assert_equal "income_account", RegisterItem.sanitize("IncomeAccount")
    assert_equal "income_account", RegisterItem.sanitize("IncomeAccount.")
    assert_equal "income_account", RegisterItem.sanitize("INCOME ACCOUNT")
  end

end
