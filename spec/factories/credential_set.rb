FactoryBot.define do

  factory :credential_set do
    association :user, factory: :user
    association :owner, factory: :user
    name { 'Twilio' }
    credential_type { 'TwilioCredentials' }

    transient do
      custom_owner { nil }
    end

    before(:create) do |credential, evaluator|
      credential.owner = evaluator.custom_owner if evaluator.custom_owner
    end

    trait :org_owner do
      association :owner, factory: :organization
    end
  end

end
