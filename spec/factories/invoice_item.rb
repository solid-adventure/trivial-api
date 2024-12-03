# spec/factories/invoice_items.rb
FactoryBot.define do
  factory :invoice_item do
    association :invoice

    income_account { "Sales" }
    income_account_group { "Revenue" }
    quantity { 2 }
    unit_price { 9.99 }
    extended_amount { quantity * unit_price }

    after(:build) do |invoice_item, _|
      invoice_item.owner = invoice_item.invoice.owner
    end
  end
end
