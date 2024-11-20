# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_11_15_132020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_entries", force: :cascade do |t|
    t.bigint "app_id"
    t.uuid "update_id"
    t.string "activity_type", null: false
    t.string "status"
    t.string "source"
    t.integer "duration_ms"
    t.jsonb "payload"
    t.jsonb "diagnostics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.bigint "register_item_id"
    t.index ["app_id"], name: "index_activity_entries_on_app_id"
    t.index ["created_at"], name: "index_activity_entries_on_created_at"
    t.index ["owner_type", "owner_id"], name: "index_activity_entries_on_owner"
    t.index ["payload"], name: "index_activity_entries_on_payload", using: :gin
    t.index ["register_item_id"], name: "index_activity_entries_on_register_item_id"
    t.index ["status"], name: "index_activity_entries_status_excluding_200", where: "((status)::text <> '200'::text)"
    t.index ["update_id"], name: "index_activity_entries_on_update_id"
  end

  create_table "apps", force: :cascade do |t|
    t.string "name", null: false
    t.integer "port", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.string "hostname", null: false
    t.string "domain", null: false
    t.string "load_balancer", null: false
    t.string "descriptive_name", null: false
    t.jsonb "panels"
    t.string "readable_by"
    t.jsonb "schedule"
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["discarded_at"], name: "index_apps_on_discarded_at"
    t.index ["name"], name: "index_apps_on_name", unique: true
    t.index ["owner_type", "owner_id"], name: "index_apps_on_owner"
    t.index ["port"], name: "index_apps_on_port", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["owner_type", "owner_id"], name: "index_audits_on_owner"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "charts", force: :cascade do |t|
    t.bigint "dashboard_id", null: false
    t.bigint "register_id", null: false
    t.string "name", null: false
    t.string "chart_type", default: "table", null: false
    t.string "color_scheme", default: "default", null: false
    t.string "report_period", null: false
    t.boolean "meta0"
    t.boolean "meta1"
    t.boolean "meta2"
    t.boolean "meta3"
    t.boolean "meta4"
    t.boolean "meta5"
    t.boolean "meta6"
    t.boolean "meta7"
    t.boolean "meta8"
    t.boolean "meta9"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "invert_sign", default: false, null: false
    t.string "default_timezones", default: ["America/New_York"], null: false, array: true
    t.string "default_time_range", default: "ytd", null: false
    t.string "report_type", default: "item_sum", null: false
    t.index ["chart_type"], name: "index_charts_on_chart_type"
    t.index ["dashboard_id"], name: "index_charts_on_dashboard_id"
    t.index ["register_id"], name: "index_charts_on_register_id"
  end

  create_table "credential_sets", force: :cascade do |t|
    t.uuid "external_id", null: false
    t.string "name", null: false
    t.string "credential_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["external_id"], name: "index_credential_sets_on_external_id", unique: true
    t.index ["owner_type", "owner_id"], name: "index_credential_sets_on_owner"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "token"
    t.string "billing_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers_users", id: false, force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.index ["customer_id"], name: "index_customers_users_on_customer_id"
    t.index ["user_id"], name: "index_customers_users_on_user_id"
  end

  create_table "dashboards", force: :cascade do |t|
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.string "dashboard_type", default: "default", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_dashboards_on_owner"
  end

  create_table "manifest_drafts", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.bigint "manifest_id", null: false
    t.jsonb "content"
    t.string "action"
    t.uuid "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["app_id"], name: "index_manifest_drafts_on_app_id"
    t.index ["manifest_id"], name: "index_manifest_drafts_on_manifest_id"
    t.index ["owner_type", "owner_id"], name: "index_manifest_drafts_on_owner"
    t.index ["token"], name: "index_manifest_drafts_on_token", unique: true
  end

  create_table "manifests", force: :cascade do |t|
    t.string "app_id"
    t.jsonb "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "internal_app_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["internal_app_id"], name: "index_manifests_on_internal_app_id"
    t.index ["owner_type", "owner_id"], name: "index_manifests_on_owner"
  end

  create_table "org_roles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_org_roles_on_organization_id"
    t.index ["user_id"], name: "index_org_roles_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "billing_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.bigint "user_id"
    t.string "permissible_type"
    t.bigint "permissible_id"
    t.integer "permit", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permissible_type", "permissible_id"], name: "index_permissions_on_permissible"
    t.index ["user_id"], name: "index_permissions_on_user_id"
  end

  create_table "register_items", force: :cascade do |t|
    t.bigint "register_id", null: false
    t.string "description"
    t.decimal "amount"
    t.string "units"
    t.string "owner_type"
    t.integer "owner_id"
    t.string "unique_key"
    t.string "meta0"
    t.string "meta1"
    t.string "meta2"
    t.string "meta3"
    t.string "meta4"
    t.string "meta5"
    t.string "meta6"
    t.string "meta7"
    t.string "meta8"
    t.string "meta9"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "originated_at"
    t.integer "invoice_id"
    t.integer "app_id"
    t.index ["app_id"], name: "index_register_items_on_app_id"
    t.index ["invoice_id"], name: "index_register_items_on_invoice_id"
    t.index ["originated_at"], name: "index_register_items_on_originated_at"
    t.index ["owner_type", "owner_id"], name: "index_register_items_on_owner_type_and_owner_id"
    t.index ["register_id"], name: "index_register_items_on_register_id"
    t.index ["unique_key", "register_id"], name: "index_register_items_on_unique_key_and_register_id", unique: true
  end

  create_table "registers", force: :cascade do |t|
    t.string "name"
    t.string "sample_type"
    t.string "units"
    t.jsonb "meta"
    t.string "owner_type"
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "context"
    t.string "name"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["taggable_type", "taggable_id"], name: "index_tags_on_taggable"
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
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "allow_password_change", default: false
    t.string "aws_role"
    t.string "current_customer_token"
    t.boolean "account_locked", default: false
    t.string "account_locked_reason"
    t.datetime "trial_expires_at", precision: nil
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.jsonb "invitation_metadata"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_entries", "apps"
  add_foreign_key "activity_entries", "register_items"
  add_foreign_key "charts", "dashboards"
  add_foreign_key "charts", "registers"
  add_foreign_key "manifest_drafts", "apps"
  add_foreign_key "manifest_drafts", "manifests"
  add_foreign_key "manifests", "apps", column: "internal_app_id"
  add_foreign_key "org_roles", "organizations"
  add_foreign_key "org_roles", "users"
  add_foreign_key "permissions", "users"
  add_foreign_key "register_items", "registers"

  create_view "activity_entry_payload_keys", materialized: true, sql_definition: <<-SQL
      WITH entry_data AS (
           SELECT activity_entries.app_id,
              jsonb_object_keys(activity_entries.payload) AS primary_key,
              activity_entries.payload
             FROM activity_entries
          ), extracted_key_data AS (
           SELECT entry_data.app_id,
              entry_data.primary_key,
              secondary_key_data.secondary_key
             FROM (entry_data
               LEFT JOIN LATERAL ( SELECT jsonb_object_keys((entry_data.payload -> entry_data.primary_key)) AS secondary_key
                    WHERE (jsonb_typeof((entry_data.payload -> entry_data.primary_key)) = 'object'::text)) secondary_key_data ON (true))
          )
   SELECT DISTINCT extracted_key_data.app_id,
      extracted_key_data.primary_key,
      extracted_key_data.secondary_key
     FROM extracted_key_data
    ORDER BY extracted_key_data.primary_key, extracted_key_data.secondary_key;
  SQL
  add_index "activity_entry_payload_keys", ["app_id"], name: "index_activity_entry_payload_keys_on_app_id"

end
