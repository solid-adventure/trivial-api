FactoryBot.define do

  factory :activity_entry do
    association :user, factory: :user
    association :owner, factory: :user
    app { FactoryBot.create(:app, user: user) }
  end

  trait :org_owner do
    association :owner, factory: :organization
  end

  trait :request do
    activity_type { 'request' }
    status { '200' }
    source { 'localhost' }
    duration_ms { 1503 }
    payload { {"test_data" => "12345" } }
    diagnostics { { "errors" => [], "events" => [] } }
  end

  trait :build do
    activity_type { 'build' }
    status { 'success' }
    duration_ms { 2839 }
  end

end
