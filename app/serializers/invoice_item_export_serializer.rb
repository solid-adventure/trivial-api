class InvoiceItemExportSerializer < ActiveModel::Serializer
  attributes :invoice_id,
    :payee_name,
    :payor_name,
    :date,
    :notes,
    :currency,
    :total,
    :created_at,
    :updated_at,
    :income_account_group,
    :income_account,
    :quantity,
    :unit_price,
    :extended_amount

  delegate :owner_id,
    :owner_name,
    :payee_id,
    :payee_name,
    :payor_id,
    :payor_name,
    :date,
    :notes,
    :currency,
    :total,
    :created_at,
    :updated_at,
    to: :invoice

  private
    def invoice
      object.invoice
    end
end
