class ActivityEntryPayloadKey < ApplicationRecord
  def readonly?
    true
  end

  def self.refresh
    Scenic.database.refresh_materialized_view('activity_entry_payload_keys', concurrently: false, cascade: false)
  end
end
