FactoryBot.define do
  factory :register do
    association :owner, factory: :user
    sequence(:name) { |n| "Register #{n}" }
    units { "USD" }
    meta {
      {
        meta0: "customer_id",
        meta1: "income_account",
        meta2: "entity_type",
        meta3: "entity_id"
      }
    }
  end
end
