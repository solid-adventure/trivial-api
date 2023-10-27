class Permission < ApplicationRecord
  include PermissionConstants

  belongs_to :user
  belongs_to :permissible, polymorphic: true

  validates :user, presence: true
  validates :permissible, presence: true
  validates :permit, presence: true

  def group_by_user(permissions)
    permissions = permissions.group_by(&:user_id)

    json_return = permissions.map do |user_id, user_permits|
    {
      user_id: user_id,
      permissions: user_permits.group_by { 
        |permission| [permission.permissible_type, permission.permissible_id] 
      }.map do |(permissible_type, permissible_id), permissions|
        permits = permissions.pluck(:permit).map { |permit| Permission::PERMISSIONS_HASH.key(permit) }
        permission_ids = permissions.pluck(:id)
        {
          permissible_type: permissible_type,
          permissible_id: permissible_id,
          permits: permits,
          ids: permission_ids
        }
      end
    }
    end

    if json_return.length == 1
      json_return.first
    else 
      json_return
    end
  end

  def group_by_resource(permissions)
    permissions = permissions.group_by { |permission| [permission.permissible_type, permission.permissible_id] }

    json_return = permissions.map do |(permissible_type, permissible_id), user_permits|
    {
      permissible_type: permissible_type,
      permissible_id: permissible_id,
      permissions: user_permits.group_by(&:user_id).map do |user_id, permissions|
        permits = permissions.pluck(:permit).map { |permit| Permission::PERMISSIONS_HASH.key(permit) }
        permission_ids = permissions.pluck(:id)
        {
          user_id: user_id,
          permits: permits,
          ids: permission_ids
        }
      end
    }
    end

    if json_return.length == 1
      json_return.first
    else 
      json_return
    end
  end
end
