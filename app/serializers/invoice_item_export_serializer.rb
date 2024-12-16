class InvoiceItemExportSerializer < ActiveModel::Serializer
  attributes :id,
    :income_account,
    :income_account_group,
    :quantity,
    :unit_price,
    :extended_amount,
    :invoice_id,
    :owner_id,
    :owner_type,
    :payee_id,
    :payee_name,
    :payor_id,
    :payor_name,
    :date,
    :notes,
    :currency,
    :total,
    :created_at,
    :updated_at

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
