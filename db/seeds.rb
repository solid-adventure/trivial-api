# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# team
team_individual = Team.new
team_individual.name = 'individual'
team_individual.save!

team1 = Team.new
team1.name = 'team1'
team1.save!

team2 = Team.new
team2.name = 'team2'
team2.save!

# user
admin = User.new
admin.name = 'admin'
admin.email = 'admin@email.com'
admin.role = 'admin'
admin.password = '12345678'
admin.team = team_individual
admin.approval = 'approved'
admin.save!

user1 = User.new
user1.name = 'user1'
user1.email = 'user1@email.com'
user1.role = 'team_manager'
user1.password = '12345678'
user1.team = team1
user1.approval = 'approved'
user1.save!

user2 = User.new
user2.name = 'user2'
user2.email = 'user2@email.com'
user2.role = 'member'
user2.password = '12345678'
user2.team = team1
user2.approval = 'approved'
user2.save!

user3 = User.new
user3.name = 'user3'
user3.email = 'user3@email.com'
user3.role = 'team_manager'
user3.password = '12345678'
user3.team = team2
user3.approval = 'approved'
user3.save!

user4 = User.new
user4.name = 'user4'
user4.email = 'user4@email.com'
user4.role = 'member'
user4.password = '12345678'
user4.team = team2
user4.approval = 'approved'
user4.save!

user5 = User.new
user5.name = 'user5'
user5.email = 'user5@email.com'
user5.role = 'member'
user5.password = '12345678'
user5.team = team2
user5.approval = 'pending'
user5.save!

user6 = User.new
user6.name = 'user6'
user6.email = 'user6@email.com'
user6.role = 'member'
user6.password = '12345678'
user6.team = team2
user6.approval = 'rejected'
user6.save!

# board
board1 = Board.new
board1.name = 'board1'
board1.owner = user1
board1.slug = 'aaaaa12345'
board1.access_level = 'free'
board1.save!

board2 = Board.new
board2.name = 'board2'
board2.owner = user2
board2.slug = 'bbbbb12345'
board2.access_level = 'trivial'
board2.save!

board3 = Board.new
board3.name = 'board3'
board3.owner = user3
board3.slug = 'ccccc12345'
board3.access_level = 'team'
board3.save!

board4 = Board.new
board4.name = 'board4'
board4.owner = user4
board4.slug = 'ddddd12345'
board4.access_level = 'secret'
board4.save!

board5 = Board.new
board5.name = 'board5'
board5.owner = user5
board5.slug = 'eeeee12345'
board5.access_level = 'secret'
board5.save!

# flow
flow1 = Flow.new
flow1.board = board1
flow1.owner = user1
flow1.name = 'flow1'
flow1.save!

flow2 = Flow.new
flow2.board = board2
flow2.owner = user2
flow2.name = 'flow2'
flow2.save!

flow3 = Flow.new
flow3.board = board3
flow3.owner = user3
flow3.name = 'flow3'
flow3.save!

# stage
stage1 = Stage.new
stage1.owner = user1
stage1.flow = flow1
stage1.name = 'stage1'
stage1.subcomponents = "[{protocol:'html', content: '<div>Hello Stage1!</div>'}]"
stage1.save!

stage2 = Stage.new
stage2.owner = user2
stage2.flow = flow1
stage2.name = 'stage2'
stage2.subcomponents = "[{protocol:'html', content: '<div>Hello Stage2!</div>'}]"
stage2.save!

# connection
connection1 = Connection.new
connection1.flow = flow1
connection1.from = stage1
connection1.to = stage2
connection1.save!
