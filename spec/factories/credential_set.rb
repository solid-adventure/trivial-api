FactoryBot.define do

  factory :credential_set do
    user
    name { 'Twilio' }
    credential_type { 'TwilioCredentials' }
  end

end
