class PermisionSerializer < ActiveModel::Serializer
  attributes :user_id, :name, :resource_id, :resource_type, :permissions

  def user_id
    object.user.id
  end

  def name
    object.user.name
  end

  def resource_id
    object.permissable.id
  end

  def resource_type
    object.permissable.class.name
  end

  def permissions
    object.permits
  end
end
