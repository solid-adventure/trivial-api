class UpdateActivityEntryPayloadKeysToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view :activity_entry_payload_keys,
      version: 2,
      revert_to_version: 1,
      materialized: true
    ActivityEntryPayloadKeys.reset_column_information
  end
end
