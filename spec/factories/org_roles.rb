# spec/factories/org_roles.rb

FactoryBot.define do
  factory :org_role do
    association :user, factory: :user
    association :organization, factory: :organization
    role { 'member' } # Default role, you can adjust as needed
  end

  # Define a factory for an admin role if needed
  factory :admin_org_role, parent: :org_role do
    role { 'admin' }
  end
end

