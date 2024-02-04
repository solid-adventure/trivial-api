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
admin.password = '12345678'
admin.approval = 'approved'
admin.save!


# TODO This concept is sound and runs well in console, but should be verified before uncommeting officially

# income_accounts = %w(carrier_fees storage receiving shipping VAS)
# user = User.third

# register1 = Register.find_or_create_by(name: "Generated Register 1", owner: user, multiplier: 0.01, units: "USD")
# register2 = Register.find_or_create_by(name: "Generated Register 2", owner: user, multiplier: 0.01, units: "USD")
# register3 = Register.find_or_create_by(name: "Generated Register 3", owner: user, multiplier: 0.01, units: "USD")
# registers = [register1, register2, register3]

# (1..10).map { |i| RegisterItem.create(
#   register: registers.sample,
#   owner: user,
#   description: "Generated event #{i}",
#   amount: rand(0.1..1000),
#   uniqueness_key: "#{Time.now}-#{i}",
#   meta: {income_account: income_accounts.sample}
# )}

