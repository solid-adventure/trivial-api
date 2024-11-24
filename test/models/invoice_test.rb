require "test_helper"

class InvoiceTest < ActiveSupport::TestCase

  def setup
    @organization = organizations(:one)
    @invoice = invoices(:one)
  end

  test "invoice requires a payee" do
    @invoice.payee = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:payee], "must exist"
  end

  test "payee must be an Organization" do
    assert_instance_of Organization, @invoice.payee
    assert_equal organizations(:one).id, @invoice.payee_org_id
  end

  test "can get organization through payee association" do
    assert_equal @organization, @invoice.payee
    assert_equal @organization.id, @invoice.payee_org_id
  end

  test "payor must be an Organization" do
    payor_org = organizations(:three)
    assert_instance_of Organization, @invoice.payor
    assert_equal payor_org.id, @invoice.payor_org_id
  end

  test "basic validations for date, currency and total" do
    assert @invoice.valid?

    @invoice.date = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:date], "can't be blank"

    @invoice.date = Date.today
    @invoice.currency = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:currency], "can't be blank"

    @invoice.currency = "USD"
    @invoice.total = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:total], "can't be blank"

    @invoice.total = -1.00
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:total], "must be greater than or equal to 0"

    @invoice.total = 19.99
    assert_not @invoice.valid?

    @invoice.total = 19.98
    assert @invoice.valid?
  end

  test "organization can access its owned invoices" do
    org = organizations(:one)
    # Both fixture invoices belong to organization one
    assert_equal 2, org.owned_invoices.count
    assert_includes org.owned_invoices, invoices(:one)
    assert_includes org.owned_invoices, invoices(:two)
    assert_instance_of Invoice, org.owned_invoices.first
  end

end
