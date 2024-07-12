# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
=begin
admin = User.new
admin.name = 'admin'
admin.email = 'admin@email.com'
admin.role = 'admin'
admin.password = '@Password123'
admin.approval = 'approved'
admin.save!

income_accounts = %w(carrier_fees storage receiving shipping VAS)
warehouses = %w(san_francisco los_angeles new_york paris london tokyo)
channels = %w(retail wholesale online popup dropship)
originated_at_range = ((DateTime.now - 2.years)..DateTime.now)

registers = (1..3).map { |i|
  org = Organization.find_or_create_by(name: "Generated Org #{i}", billing_email: user.email)
  OrgRole.find_or_create_by(user: user, organization: org, role: "admin")

  columns = (1..9).map { |i| "meta#{i}" }.sample(3)
  meta = Hash[columns.zip(%w[income_account warehouse channel])]

  Register.find_or_create_by(
    name: "Sales",
    owner: org,
    units: "USD",
    meta: meta
  )
}

2000.times do |i|
  register = registers.sample
  item = RegisterItem.new(
    register_id: register.id,
    owner: register.owner,
    description: "Generated event #{i}",
    amount: rand(0.1..20.0).round(2),
    units: "USD",
    unique_key: "#{Time.now}-#{i}",
    originated_at: rand(originated_at_range)
  )
  meta = register.meta.invert
  item[meta["income_account"]] = income_accounts.sample
  item[meta["warehouse"]] = warehouses.sample
  item[meta["channel"]] = channels.sample
  item.save!
end
=end

app = App.last
owner = app.owner

size = 50
alphabet = ('a'...'z').to_a
k = Array.new(size) { 8.times.map { alphabet.sample }.join }
v = Array.new(size) { SecureRandom.hex(4) }

event_types = %i[
                  item invoice project shipnotice order shipnotice_item consumer_return
                  void_item void_invoice void_shipnotice void_order
                  void_project void_shipnotice_item void_consumer_return random
                ]
statuses = Array.new(99, "200") + [ "500" ]

10.times do |i|
  entry_array = []
  300000.times do |j|
    random_hash = 16.times
      .map { k.sample }
      .zip( 16.times.map { v.sample } )
      .to_h

    payload = {
                event_name: "generated_event #{ (j + 1) * (i + 1) }",
                key: "generated_key #{ (j + 1) * (i + 1) }",
                event_types.sample => random_hash
              }

    entry_array.push(
      {
        activity_type: "generated_activity",
        app_id: app.id,
        owner_id: owner.id,
        owner_type: "Organization",
        payload: payload,
        diagnostics: {},
        status: statuses.sample,
        duration_ms: rand(2000...60000)
      }
    )
  end
  ActivityEntry.insert_all(entry_array)
end
