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

    trait :permissible do
      after(:create) do |app, _evaluator|
        if app.owner.is_a?(User)
          Permission.grant_all(
            permissible: app,
            user_ids: app.owner.id
          )
        else # owner is an Organization
          Permission.grant_all(
            permissible: app,
            user_ids: app.owner.org_roles.where(role: 'admin').pluck(:user_id)
          )
          Permission.grant(
            permissible: app,
            user_ids: app.owner.org_roles.where(role: 'member').pluck(:user_id),
            permit: :read
          )
        end
      end
    end
  end
end
