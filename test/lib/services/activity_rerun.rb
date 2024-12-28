require 'test_helper'

class ActivityRerunTest < ActiveSupport::TestCase

  def setup
    @app = apps(:one)
    @start_at = Time.parse("2024-11-01 00:00:00")
    @end_at = Time.parse("2024-11-30 23:59:59")
    @register = registers(:one)
    @owner = organizations(:one)
    @run_id = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')

    # Store fixture IDs for easy reference in tests
    @before_start_at_id = register_items(:rerun_before_start_date).id
    @with_invoice_id = register_items(:rerun_with_invoice).id
    @other_app_id = register_items(:rerun_other_app).id
    @deletable_id_1 = register_items(:rerun_deletable_one).id
    @deletable_id_2 = register_items(:rerun_deletable_two).id

    @register_item_ids = [
      @before_start_at_id,
      @with_invoice_id,
      @other_app_id,
      @deletable_id_1,
      @deletable_id_2
    ]

    @rerun_before_start_date = activity_entries(:rerun_before_start_date)
    @rerun_after_start_date = activity_entries(:rerun_after_start_date)
    @rerun_after_start_date_two = activity_entries(:rerun_after_start_date_two)

  end

  test 'can instantiate' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)
    assert_instance_of Services::ActivityRerun, service
  end

  test 'run_id is accessible' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)
    assert_equal @run_id, service.run_id
  end

  test 'delete_register_items removes eligible records after start_at' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)

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

  test 'reset_activity_entries resets eligible records after start' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)

    reset_count = service.send(:reset_activity_entries)
    assert_equal 2, reset_count, "Expected 2 records to be reset"

    # This record should be reset
    assert_nil @rerun_after_start_date.reload.register_item_id, "Expected register_item_id to be nil"
    assert_nil @rerun_after_start_date.diagnostics, "Expected diagnostics to be nil"
    assert_nil @rerun_after_start_date.status, "Expected status to be nil"
    assert_nil @rerun_after_start_date.duration_ms, "Expected duration_ms to be nil"

    # This record should be unchanged
    @rerun_before_start_date.reload
    assert_not_nil @rerun_before_start_date.register_item_id, "Expected register_item_id to be unchanged"
    assert_not_nil @rerun_before_start_date.diagnostics, "Expected diagnostics to be unchanged"
    assert_not_nil @rerun_before_start_date.status, "Expected status to be unchanged"
    assert_not_nil @rerun_before_start_date.duration_ms, "Expected duration_ms to be unchanged"
  end

  test 'queue_activities_for_rerun queues eligible records after start' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)
    queued_count = service.send(:queue_activities_for_rerun)
    assert_equal 2, queued_count, "Expected 2 records to be queued"
  end

  test 'lock key contains app id' do
    service = Services::ActivityRerun.new(app: @app, start_at: @start_at, end_at: @end_at, run_id: @run_id)
    assert_equal "rerun_app_#{@app.id}", service.send(:lock_key)
  end

end
