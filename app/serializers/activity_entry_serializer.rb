class ActivityEntrySerializer < ActiveModel::Serializer
  attributes :id, :owner_id, :owner_type, :app_id, :register_item_id, :activity_type, :status, :duration_ms, :created_at
end
