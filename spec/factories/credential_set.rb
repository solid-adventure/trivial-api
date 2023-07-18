require 'user'

FactoryBot.define do

  factory :credential_set do
    association :owner, factory: :user
    name { 'Twilio' }
    credential_type { 'TwilioCredentials' }
  end

end
