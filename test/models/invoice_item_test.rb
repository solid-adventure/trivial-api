require "test_helper"

class InvoiceItemTest < ActiveSupport::TestCase
  setup do
    @invoice_item = invoice_items(:one)
  end

  test "invoice item belongs to an invoice" do
    assert_respond_to @invoice_item, :invoice
    assert_instance_of Invoice, @invoice_item.invoice
    assert_equal invoices(:one), @invoice_item.invoice
  end

  test "unit price must be present" do
    @invoice_item.unit_price = nil
    assert_not @invoice_item.valid?
    assert_includes @invoice_item.errors[:unit_price], "can't be blank"
  end

  test "unit price must be greater than or equal to zero" do
    @invoice_item.unit_price = -1
    assert_not @invoice_item.valid?
    assert_includes @invoice_item.errors[:unit_price], "must be greater than or equal to 0"
  end

  test "before_save calculates extended amount" do
    invoice_item = InvoiceItem.new(
      invoice: invoices(:one),
      quantity: 3,
      unit_price: 5.99,
      income_account: 'direct_to_consumer',
      income_account_group: 'Outbound',
      owner_type: 'Organization',
      owner_id: 1
    )

    invoice_item.save
    puts invoice_item.errors.full_messages
    assert_equal 17.97, invoice_item.extended_amount
  end

  test "before_save recalculates extended amount when quantity changes" do
    @invoice_item.quantity = 3  # Original was 2
    @invoice_item.save
    assert_equal 29.97, @invoice_item.extended_amount  # 3 * 9.99
  end

  test "before_save recalculates extended amount when unit_price changes" do
    @invoice_item.unit_price = 5.99  # Original was 9.99
    @invoice_item.save
    assert_equal 11.98, @invoice_item.extended_amount  # 2 * 5.99
  end

  test "extended_amount cannot be set directly" do
    invoice_item = InvoiceItem.new(
      invoice: invoices(:one),
      quantity: 2,
      unit_price: 10.00,
      extended_amount: 25.00,  # Attempting to set directly
      income_account: 'direct_to_consumer',
      income_account_group: 'Outbound',
      owner_type: 'Organization',
      owner_id: 1
    )
    assert_not invoice_item.valid?
    assert_includes invoice_item.errors[:extended_amount], "cannot be set directly"
  end

  test "extended_amount calculation handles decimals precisely" do
    invoice_item = InvoiceItem.new(
      invoice: invoices(:one),
      quantity: 3,
      unit_price: 10.99,
      income_account: 'direct_to_consumer',
      income_account_group: 'Outbound',
      owner_type: 'Organization',
      owner_id: 1
    )
    assert invoice_item.valid?
    assert_equal 32.97, invoice_item.extended_amount
  end

  test "extended_amount updates correctly when saved without changes" do
    @invoice_item.save
    original_amount = @invoice_item.extended_amount
    @invoice_item.save
    assert_equal original_amount, @invoice_item.extended_amount
  end

end