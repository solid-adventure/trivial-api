FactoryBot.define do

  factory :app do
    association :user, factory: :user
    association :owner, factory: :user
    sequence(:descriptive_name) {|n| "Test App \##{n}"}

    trait :org_owner do
      association :owner, factory: :organization
    end
  end

end
