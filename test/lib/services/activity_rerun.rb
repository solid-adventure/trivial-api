require 'test_helper'

class ActivityRerunTest < ActiveSupport::TestCase
  fixtures :apps

  def setup
    @app = apps(:one)
    @start_at = Time.parse"2024-11-01 00:00:00"

    @register = registers(:one)
    @owner = organizations(:one)

  # Store IDs as we create records
    @before_start_at_id = RegisterItem.create!(
      app: @app, originated_at: @start_at - 1.day, invoice_id: nil,
      register: @register, description: "Test Item 3", amount: 300, units: 3, owner: @owner, unique_key: 1
    ).id

    @with_invoice_id = RegisterItem.create!(
      app: @app, originated_at: @start_at + 1.day, invoice_id: 123,
      register: @register, description: "Test Item 4", amount: 400, units: 4, owner: @owner, unique_key: 2
    ).id

    @other_app_id = RegisterItem.create!(
      app: apps(:two), originated_at: @start_at + 1.day, invoice_id: nil,
      register: @register, description: "Test Item 5", amount: 500, units: 5, owner: @owner, unique_key: 3
    ).id

    @deletable_id_1 = RegisterItem.create!(
      app: @app, originated_at: @start_at + 1.day, invoice_id: nil,
      register: @register, description: "Test Item 1", amount: 100, units: 1, owner: @owner, unique_key: 4
    ).id

    @deletable_id_2 = RegisterItem.create!(
      app: @app, originated_at: @start_at + 2.days, invoice_id: nil,
      register: @register, description: "Test Item 2", amount: 200, units: 2, owner: @owner, unique_key: 5
    ).id

    @register_item_ids = [
      @before_start_at_id,
      @with_invoice_id,
      @other_app_id,
      @deletable_id_1,
      @deletable_id_2
    ]
  end

  test 'can instantiate' do
    service = Services::ActivityRerun.new(@app, @start_at)
    assert_instance_of Services::ActivityRerun, service
  end

  test 'generates a 6 digit run_id' do
    service = Services::ActivityRerun.new(@app, @start_at)
    run_id = service.send(:run_id)
    assert_match(/^\d{6}$/, run_id)
  end

  test 'delete_register_items removes eligible records after start_at' do
    service = Services::ActivityRerun.new(@app, @start_at)

    deleted_count = service.send(:delete_register_items)
    assert_equal 2, deleted_count, "Expected 2 records to be deleted"

    remaining_records = RegisterItem.where(id: @register_item_ids)
    assert_equal 3, remaining_records.count, "Expected 3 records to remain"

    # These IDs should still exist
    assert RegisterItem.exists?(@before_start_at_id), "Expected ID @before_start_at_id to still exist"
    assert RegisterItem.exists?(@with_invoice_id), "Expected ID @with_invoice_id to still exist"
    assert RegisterItem.exists?(@other_app_id), "Expected ID @other_app_id to still exist"

    # These IDs should be gone
    refute RegisterItem.exists?(@deletable_id_1), "Expected ID @deletable_id_1 to be deleted"
    refute RegisterItem.exists?(@deletable_id_2), "Expected ID @deletable_id_2 to be deleted"
  end

end
