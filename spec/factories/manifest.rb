FactoryBot.define do

   factory :manifest do
     app_id { app_id }
     internal_app_id { internal_app_id } 
     content { '{}'}
     association :user, factory: :user
     association :owner, factory: :user

     trait :org_owner do
       association :owner, factory: :organization
     end
   end

 end
