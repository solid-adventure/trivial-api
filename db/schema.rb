# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_201_127_144_321) do
  create_table 'boards', force: :cascade do |t|
    t.integer 'owner_id'
    t.string 'name', default: '', null: false
    t.string 'slug', null: false
    t.integer 'access_level', default: 0, null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['owner_id'], name: 'index_boards_on_owner_id'
  end

  create_table 'boards_users', force: :cascade do |t|
    t.integer 'board_id'
    t.integer 'user_id'
    t.index ['board_id'], name: 'index_boards_users_on_board_id'
    t.index ['user_id'], name: 'index_boards_users_on_user_id'
  end

  create_table 'connections', force: :cascade do |t|
    t.integer 'from_id'
    t.integer 'to_id'
    t.integer 'flow_id'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['flow_id'], name: 'index_connections_on_flow_id'
    t.index ['from_id'], name: 'index_connections_on_from_id'
    t.index ['to_id'], name: 'index_connections_on_to_id'
  end

  create_table 'flows', force: :cascade do |t|
    t.integer 'owner_id'
    t.integer 'board_id'
    t.string 'name', default: '', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['board_id'], name: 'index_flows_on_board_id'
    t.index ['owner_id'], name: 'index_flows_on_owner_id'
  end

  create_table 'flows_users', force: :cascade do |t|
    t.integer 'flow_id'
    t.integer 'user_id'
    t.index ['flow_id'], name: 'index_flows_users_on_flow_id'
    t.index ['user_id'], name: 'index_flows_users_on_user_id'
  end

  create_table 'stages', force: :cascade do |t|
    t.integer 'owner_id'
    t.integer 'flow_id'
    t.string 'name', default: '', null: false
    t.text 'subcomponents'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['flow_id'], name: 'index_stages_on_flow_id'
    t.index ['owner_id'], name: 'index_stages_on_owner_id'
  end

  create_table 'stages_users', force: :cascade do |t|
    t.integer 'stage_id'
    t.integer 'user_id'
    t.index ['stage_id'], name: 'index_stages_users_on_stage_id'
    t.index ['user_id'], name: 'index_stages_users_on_user_id'
  end

  create_table 'teams', force: :cascade do |t|
    t.string 'name', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
  end

  create_table 'users', force: :cascade do |t|
    t.string 'provider', default: 'email', null: false
    t.string 'uid', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'name'
    t.string 'email'
    t.text 'tokens'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.integer 'team_id', null: false
    t.integer 'role', default: 0, null: false
    t.integer 'approval', default: 0, null: false
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index %w[uid provider], name: 'index_users_on_uid_and_provider', unique: true
  end

  add_foreign_key 'boards', 'users', column: 'owner_id'
  add_foreign_key 'connections', 'stages', column: 'from_id'
  add_foreign_key 'connections', 'stages', column: 'to_id'
  add_foreign_key 'flows', 'users', column: 'owner_id'
  add_foreign_key 'stages', 'users', column: 'owner_id'
end
