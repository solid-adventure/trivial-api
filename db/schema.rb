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

ActiveRecord::Schema.define(version: 2021_11_05_225600) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "port", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "hostname", null: false
    t.string "domain", null: false
    t.string "load_balancer", null: false
    t.string "descriptive_name", null: false
  end

  create_table "manifest_drafts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
    t.bigint "manifest_id", null: false
    t.jsonb "content"
    t.string "action"
    t.uuid "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manifests", force: :cascade do |t|
    t.string "app_id"
    t.jsonb "content"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "internal_app_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.integer "approval", default: 0, null: false
    t.string "color_theme"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.string "aws_role"
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "app_id"
    t.jsonb "payload"
    t.string "source"
    t.string "topic"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "status"
    t.jsonb "diagnostics"
  end

  add_foreign_key "apps", "users", name: "apps_user_id_fkey"
  add_foreign_key "manifest_drafts", "apps", name: "manifest_drafts_app_id_fkey"
  add_foreign_key "manifest_drafts", "manifests", name: "manifest_drafts_manifest_id_fkey"
  add_foreign_key "manifest_drafts", "users", name: "manifest_drafts_user_id_fkey"
  add_foreign_key "manifests", "apps", column: "internal_app_id", name: "manifests_internal_app_id_fkey"
end
