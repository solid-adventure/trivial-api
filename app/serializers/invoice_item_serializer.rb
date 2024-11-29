class InvoiceItemSerializer < ActiveModel::Serializer
  attributes :id, :owner_type, :owner_id, :invoice_id, :income_account, :income_account_group, :quantity, :unit_price, :extended_amount, :created_at, :updated_at
end
