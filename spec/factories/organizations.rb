# spec/factories/organizations.rb

FactoryBot.define do
  factory :organization do
    name { 'Organization Alpha' }
    billing_email { 'alpha@email.com' }

    # Create users and assign roles through OrgRole
    transient do
      users_count { 3 } # Adjust the number of users as needed
    end

    after(:create) do |organization, evaluator|
      admin_created = false

      evaluator.users_count.times do
        role = admin_created ? 'member' : 'admin'
        user = create(:user)
        create(:org_role, user: user, organization: organization, role: role)
        admin_created = true if role == 'admin'
      end
    end 
  end
end
