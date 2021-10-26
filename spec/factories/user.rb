FactoryBot.define do

  factory :user do
    name { 'Test User' }
    sequence(:email) {|n| "user#{n}@example.test"}
    password { 'insecure' }
    aws_role { 'testlambda-ex-1' }
  end

  trait :logged_in do
    tokens do
      token = DeviseTokenAuth::TokenFactory.create
      {
        token.client => {
          'token' => token.token_hash,
          'expiry' => token.expiry,
          'token_unhashed' => token.token # only for use in tests
        }
      }
    end
  end

end
