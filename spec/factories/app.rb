FactoryBot.define do

  factory :app do
    association :user, factory: :user
    association :owner, factory: :user
    sequence(:descriptive_name) {|n| "Test App \##{n}"}

    transient do
      custom_owner { nil }
    end

    before(:create) do |app, evaluator|
      app.owner = evaluator.custom_owner if evaluator.custom_owner
    end

    trait :org_owner do
      association :owner, factory: :organization
    end

    after(:create) do |app, _evaluator|
      if app.owner.is_a?(Organization)
        app.grant(
          user_ids: app.owner.org_roles.where(role: 'member').pluck(:user_id),
          permit: :read
        )
      end
    end
  end
end
