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

ActiveRecord::Schema.define(version: 2021_08_30_140625) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "port", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "discarded_at"
    t.string "hostname", null: false
    t.string "domain", null: false
    t.string "load_balancer", null: false
    t.index ["discarded_at"], name: "index_apps_on_discarded_at"
    t.index ["name"], name: "index_apps_on_name", unique: true
    t.index ["port"], name: "index_apps_on_port", unique: true
    t.index ["user_id"], name: "index_apps_on_user_id"
  end

  create_table "boards", force: :cascade do |t|
    t.bigint "owner_id"
    t.string "name", default: "", null: false
    t.string "slug", null: false
    t.integer "access_level", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "contents"
    t.text "description"
    t.string "meta_description"
    t.boolean "featured"
    t.index ["owner_id"], name: "index_boards_on_owner_id"
  end

  create_table "boards_users", force: :cascade do |t|
    t.bigint "board_id"
    t.bigint "user_id"
    t.index ["board_id"], name: "index_boards_users_on_board_id"
    t.index ["user_id"], name: "index_boards_users_on_user_id"
  end

  create_table "connections", force: :cascade do |t|
    t.bigint "flow_id"
    t.string "transform"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "from_stage_id"
    t.integer "to_stage_id"
    t.string "from"
    t.string "to"
    t.index ["flow_id"], name: "index_connections_on_flow_id"
  end

  create_table "flows", force: :cascade do |t|
    t.bigint "board_id"
    t.string "name", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["board_id"], name: "index_flows_on_board_id"
  end

  create_table "manifests", force: :cascade do |t|
    t.string "app_id"
    t.json "content"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "internal_app_id"
    t.index ["internal_app_id"], name: "index_manifests_on_internal_app_id"
  end

  create_table "stages", force: :cascade do |t|
    t.bigint "flow_id"
    t.string "name", default: "", null: false
    t.text "subcomponents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["flow_id"], name: "index_stages_on_flow_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "team_id"
    t.integer "role", default: 0, null: false
    t.integer "approval", default: 0, null: false
    t.string "color_theme"
    t.string "reset_password_token"
<<<<<<< HEAD
    t.datetime "reset_password_sent_at"
=======
    t.datetime "reset_password_token_sent_at"
>>>>>>> main
    t.boolean "allow_password_change", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "app_id"
    t.json "payload"
    t.string "source"
    t.string "topic"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "status"
    t.json "diagnostics"
  end

  add_foreign_key "apps", "users"
  add_foreign_key "boards", "users", column: "owner_id"
  add_foreign_key "manifests", "apps", column: "internal_app_id"
end
