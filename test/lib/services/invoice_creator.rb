require 'test_helper'

class InvoiceCreatorTest < ActiveSupport::TestCase

  def setup
    @register = registers(:four)
    @owner = organizations(:one)
    @customer_id = 1
    @end_date = Time.parse('2024-11-30')
    @period = 'month'
    @invoice_groups = ['warehouse_id']

    @service = Services::InvoiceCreator.new(
      @register,
      @customer_id,
      @end_date,
      @period,
      @invoice_groups
    )

  end

  test 'can initialize' do
    assert_instance_of Services::InvoiceCreator, @service
  end

  test 'is not valid with missing meta columns' do
    service = Services::InvoiceCreator.new(
      registers(:one),
      @customer_id,
      @end_date,
      @period,
      @invoice_groups
    )
    assert_not service.valid
  end

  test 'is valid with all required meta columns' do
    assert @service.valid
  end

  test 'derives start and end dates from end date and period' do
    @service.set_range("America/New_York")
    service_start = @service.instance_variable_get(:@start_at)
    start_of_month = Time.parse('2024-11-01').in_time_zone("America/New_York").beginning_of_day
    assert_equal start_of_month, service_start

    service_end = @service.instance_variable_get(:@end_at)
    end_of_month = Time.parse('2024-11-30').in_time_zone("America/New_York").end_of_day
    assert_equal end_of_month, service_end
  end

  test 'can derive meta columns from labels' do
    groups = @service.send(:meta_groups, @invoice_groups)
    assert_equal(["meta3"], groups)
  end

  test 'to_invoice correctly scopes already invoiced register items' do
    register_items = @service.to_invoice
    assert_equal(2, register_items.count)
    assert_equal([9,10], register_items.pluck(:id))
  end

  test 'to_invoice handles provided group_filter' do
    register_items = @service.to_invoice({ "warehouse_id" => 1 })
    assert_equal(1, register_items.count)
    assert_equal([9], register_items.pluck(:id))

    register_items = @service.to_invoice({ "warehouse_id" => 2 })
    assert_equal(1, register_items.count)
    assert_equal([10], register_items.pluck(:id))
  end

  test 'creates invoices' do
    assert_difference 'Invoice.count', 2 do
      @service.create!
    end
  end

  test 'creates invoice items' do
    assert_difference 'InvoiceItem.count', 2 do
      @service.create!
    end
  end

  test 'correctly scopes to customer' do
    register_items = @service.to_invoice
    assert_not register_items.pluck(:id).include?(11), "register_item 11 is owned by another customer"
  end

end