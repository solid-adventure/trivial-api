# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

admin = User.new
admin.name = 'admin'
admin.email = 'admin@email.com'
admin.role = 'admin'
admin.password = '@Password123'
admin.approval = 'approved'
admin.save!
user = User.last

income_accounts = %w(carrier_fees storage receiving shipping VAS)
warehouses = %w(san_francisco los_angeles new_york paris london tokyo)
channels = %w(retail wholesale online popup dropship)
originated_at_range = ((DateTime.now - 2.years)..DateTime.now)

register1 = Register.find_or_create_by(name: "Generated Register 1", owner: user, units: "USD", meta: {meta0: "income_account", meta1: "warehouse", meta2: "channel" })
register2 = Register.find_or_create_by(name: "Generated Register 2", owner: user, units: "USD", meta: {meta0: "income_account", meta1: "warehouse", meta2: "channel" })
register3 = Register.find_or_create_by(name: "Generated Register 3", owner: user, units: "USD", meta: {meta0: "income_account", meta1: "warehouse", meta2: "channel" })
registers = [register1, register2, register3]

2000.times do |i|
  RegisterItem.create(
    register_id: registers.sample.id,
    owner: user,
    description: "Generated event #{i}",
    amount: rand(0.1..20.0).round(2),
    units: "USD",
    unique_key: "#{Time.now}-#{i}",
    income_account: income_accounts.sample,
    warehouse: warehouses.sample,
    channel: channels.sample, 
    originated_at: rand(originated_at_range)
  )
end
