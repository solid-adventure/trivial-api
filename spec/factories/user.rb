FactoryBot.define do

  factory :user do
    sequence(:name) {|n| "User \##{n}" }
    sequence(:email) {|n| "user#{n}@email.com"}
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
