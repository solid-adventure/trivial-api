class OrgRoleSerializer < ActiveModel::Serializer
  attributes :user_id, :organization_id, :role
end
