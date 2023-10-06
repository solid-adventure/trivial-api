# spec/factories/organizations.rb

FactoryBot.define do
  factory :organization do
    sequence(:name) {|n| "Organization \##{n}"}
    sequence(:billing_email) {|n| "org#{n}@email.com" }

    # Create users and assign roles through OrgRole
    # Organizations should always have at least 1 user with 'admin'
    transient do
      members_count { 0 } # Adjust the number of additional members as needed
      admin { User.first }
    end

    after(:create) do |organization, evaluator|
      if evaluator.admin
        admin = evaluator.admin
      elsif User.none?
        admin = create(:user)
      else
        admin = User.first
      end
      create(:org_role, user: admin, organization: organization, role: 'admin')

      evaluator.members_count.times do
        user = create(:user)
        create(:org_role, user: user, organization: organization, role: 'member')
      end
    end 
  end
end
