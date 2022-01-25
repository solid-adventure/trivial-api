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

ActiveRecord::Schema.define(version: 2022_01_25_153646) do

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
    t.string "descriptive_name", null: false
    t.index ["descriptive_name"], name: "index_apps_on_descriptive_name", unique: true
    t.index ["discarded_at"], name: "index_apps_on_discarded_at"
    t.index ["name"], name: "index_apps_on_name", unique: true
    t.index ["port"], name: "index_apps_on_port", unique: true
    t.index ["user_id"], name: "index_apps_on_user_id"
  end

  create_table "credential_sets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "credential_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_credential_sets_on_user_id"
  end

  create_table "manifest_drafts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
    t.bigint "manifest_id", null: false
    t.jsonb "content"
    t.string "action"
    t.uuid "token", null: false
    t.datetime "expires_at", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["app_id"], name: "index_manifest_drafts_on_app_id"
    t.index ["manifest_id"], name: "index_manifest_drafts_on_manifest_id"
    t.index ["token"], name: "index_manifest_drafts_on_token", unique: true
    t.index ["user_id"], name: "index_manifest_drafts_on_user_id"
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

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "role", default: 0, null: false
    t.integer "approval", default: 0, null: false
    t.string "color_theme"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.string "aws_role"
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
  add_foreign_key "credential_sets", "users"
  add_foreign_key "manifest_drafts", "apps"
  add_foreign_key "manifest_drafts", "manifests"
  add_foreign_key "manifest_drafts", "users"
  add_foreign_key "manifests", "apps", column: "internal_app_id"
end
