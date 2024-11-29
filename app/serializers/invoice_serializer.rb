class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :owner_type, :owner_id, :payee_ord_id, :payor_org_id, :date, :notes, :currency, :total, :created_at, :updated_at
  has_many :invoice_items
end
