FactoryBot.define do

  factory :manifest do
    app_id { app_id }
    content { '{}'}
    user
    internal_app_id { internal_app_id } 
  end

end
