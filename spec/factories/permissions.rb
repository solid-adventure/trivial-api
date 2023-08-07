FactoryBot.define do
  factory :permission do
    name { "MyString" }
    description { "MyText" }
    resource_id { "" }
    resource_type { "MyString" }
    access { "MyString" }
    assigned_id { "" }
    assigned_type { "MyString" }
  end
end
