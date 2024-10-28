# spec/factories/chart.rb

FactoryBot.define do
  factory :chart do
    association :dashboard, factory: :dashboard
    association :register, factory: :register
    sequence(:name) { |n| "Chart #{n}" }
    sequence :chart_type, %i[bar line heat_map random pie].cycle
    report_period { 'month' }
    default_timezones { ['America/New_York', 'America/Los_Angeles'] }
    default_time_range { 'ytd' }
    meta0 { register.meta.key?('meta0') ? false : nil }
    meta1 { register.meta.key?('meta1') ? false : nil }
    meta2 { register.meta.key?('meta2') ? false : nil }
    meta3 { register.meta.key?('meta3') ? false : nil }
    meta4 { register.meta.key?('meta4') ? false : nil }
    meta5 { register.meta.key?('meta5') ? false : nil }
    meta6 { register.meta.key?('meta6') ? false : nil }
    meta7 { register.meta.key?('meta7') ? false : nil }
    meta8 { register.meta.key?('meta8') ? false : nil }
    meta9 { register.meta.key?('meta9') ? false : nil }
  end
end
