class DropWebhooks < ActiveRecord::Migration[6.0]
  def change
    drop_table :webhooks do |t|
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
  end
end
