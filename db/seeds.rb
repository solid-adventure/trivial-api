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
