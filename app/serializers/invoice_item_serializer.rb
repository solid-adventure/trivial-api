class InvoiceItemSerializer < ActiveModel::Serializer
  attributes :id,
    :invoice_id,
    :owner_id,
    :owner_type,
    :income_account,
    :income_account_group,
    :quantity,
    :unit_price,
    :extended_amount,
    :created_at,
    :updated_at
end
