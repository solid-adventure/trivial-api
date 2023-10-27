class PermissionSerializer < ActiveModel::Serializer
  include JSONAPI::Serializer

  set_type :permission

  attributes :id, :user_id, :permissible_id, :permissible_type, :permit
end
