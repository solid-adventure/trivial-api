class PermissionSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :permissible_id, :permissible_type, :permit
end
