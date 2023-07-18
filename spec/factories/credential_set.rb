FactoryBot.define do

  factory :credential_set do
    owner { create(:user) }
    name { 'Twilio' }
    credential_type { 'TwilioCredentials' }
  end

end
