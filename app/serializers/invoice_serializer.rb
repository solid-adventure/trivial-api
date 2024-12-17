class InvoiceSerializer < ActiveModel::Serializer
  attributes :id,
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
  has_many :invoice_items
end
