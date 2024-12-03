# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :owner, factory: :organization
    association :payee, factory: :organization
    association :payor, factory: :organization
    date { Date.today }
    notes { 'Test Notes' }
    currency { "USD" }
    total { 0.0 }

    transient do
      invoice_items_count { 2 }
    end

    after(:build) do |invoice, _|
      invoice.register = invoice.owner.owned_registers.first
    end

    after(:create) do |invoice, evaluator|
      create_list(:invoice_item, evaluator.invoice_items_count, invoice: invoice)
      invoice.update!(total: invoice.invoice_items.sum(:extended_amount))
    end
  end
end
