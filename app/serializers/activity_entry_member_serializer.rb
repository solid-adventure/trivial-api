class ActivityEntryMemberSerializer < ActiveModel::Serializer
  attributes :id, :payload, :update_id, :owner_id, :owner_type, :app_id, :register_item_id, :activity_type, :status, :duration_ms, :created_at

  def app_id
    object.app.name
  end
end