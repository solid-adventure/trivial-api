# spec/factories/register_item.rb

FactoryBot.define do
  factory :register_item do
    association :register
    owner { register.owner }
    invoice { nil }
    sequence(:description) { |n| "RegisterItem #{n}" }
    amount { 2.50 }
    units { register.units }
    originated_at { Time.now }
    sequence(:unique_key) { |n| "Order.#{n}.#{originated_at}" }

    # meta column labels are sourced from register.meta
    meta0 { "29" } # default customer_id
    sequence(:meta1) { |n| "Account #{n}" } # default income_account
    meta2 { "Order" } # default entity_type
    sequence(:meta3) { |n| "#{n}" } # default entity_id
    # meta[4-9] default to nil and have no default label
  end
end
