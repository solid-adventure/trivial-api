FactoryBot.define do
  factory :manifest do
    content { '{}'}
    association :user, factory: :user
    association :owner, factory: :user
    association :app, factory: :app

    transient do
      custom_app { nil }
    end

    before(:create) do |manifest, evaluator|
      manifest.app = evaluator.custom_app if evaluator.custom_app
      
      manifest.app_id = manifest.app.name
      manifest.internal_app_id = manifest.app.id
      manifest.owner = manifest.app.owner
    end

    after(:create) do |manifest, _evaluator|
      manifest.grant_all(user_ids: manifest.owner.id)
    end

    trait :org_owner do
      association :owner, factory: :organization
    end
  end
end
