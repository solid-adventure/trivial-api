# spec/factories/dashboard.rb

FactoryBot.define do
  factory :dashboard do
    association :owner, factory: :organization
    sequence(:name) { |n| "#{owner.name} Dashboard #{n}" }
  end
end
