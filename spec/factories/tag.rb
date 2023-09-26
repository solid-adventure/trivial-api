FactoryBot.define do

  factory :tag do
    taggable { FactoryBot.create(:app, user: user) }
  end

end
