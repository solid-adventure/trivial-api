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

end