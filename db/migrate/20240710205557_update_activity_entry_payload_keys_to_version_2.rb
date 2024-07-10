class UpdateActivityEntryPayloadKeysToVersion2 < ActiveRecord::Migration[7.0]
  def change
    replace_view :activity_entry_payload_keys,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
