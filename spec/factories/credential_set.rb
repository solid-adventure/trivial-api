FactoryBot.define do

  factory :credential_set do
    association :owner, factory: :user
    name { 'Twilio' }
    credential_type { 'TwilioCredentials' }

    trait :org_owner do
      association :owner, factory: :organization
    end
  end

end
