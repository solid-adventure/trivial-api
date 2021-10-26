FactoryBot.define do

  factory :app do
    user
    sequence(:descriptive_name) {|n| "Test App \##{n}"}
  end

end
