class PermissionSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :permissable_id, :permissable_type, :permit
end
