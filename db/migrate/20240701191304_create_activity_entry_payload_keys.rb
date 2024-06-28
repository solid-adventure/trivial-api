class CreateActivityEntryPayloadKeys < ActiveRecord::Migration[7.0]
  def change
    create_view :activity_entry_payload_keys, materialized: true
    add_index :activity_entry_payload_keys, :app_id
  end
end
