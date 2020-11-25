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

ActiveRecord::Schema.define(version: 2020_11_25_151227) do

  create_table "boards", force: :cascade do |t|
    t.integer "owner_id"
    t.string "name", default: "", null: false
    t.string "url", default: "", null: false
    t.integer "permission", default: 0, null: false
    t.index ["owner_id"], name: "index_boards_on_owner_id"
  end

  create_table "boards_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "board_id", null: false
    t.index ["board_id"], name: "index_boards_users_on_board_id"
    t.index ["user_id"], name: "index_boards_users_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", default: "", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.integer "team_id"
    t.integer "role", default: 2, null: false
    t.integer "approval", default: 2, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "boards", "users", column: "owner_id"
end
