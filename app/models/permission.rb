class Permission < ApplicationRecord
  include PermissionConstants

  audited

  belongs_to :user
  belongs_to :permissible, polymorphic: true

  validates :user, presence: true
  validates :permissible, presence: true
  validates :permit, presence: true

  def self.permissions_for(user)
    # we only care about special permissions. read and create are excluded
    permissions = {
      update: {},
      destroy: {},
      grant: {},
      transfer: {}
    }

    # id apps by name
    owned_apps = user.owned_apps.pluck(:name)
    managed_apps = App.where(owner: user.organizations.where(org_roles: { role: "admin" })).pluck(:name)

    # id credential_sets by id
    owned_credentials = user.owned_credential_sets.pluck(:id)
    managed_credentials = CredentialSet.where(owner: user.organizations.where(org_roles: { role: "admin" })).pluck(:id)

    # build the resource permission arrays and return permissions
    permissions.each do |ability, resources|
      permission_conditions = { user: user, permit: PERMISSIONS_HASH[ability] }

      permitted_app_ids = Permission
        .where(permission_conditions.merge(permissible_type: "App"))
        .pluck(:permissible_id)
      permitted_apps = App.where(id: permitted_app_ids).pluck(:name)

      permitted_credentials = Permission
        .where(permission_conditions.merge(permissible_type: "CredentialSet"))
        .pluck(:permissible_id)

      resources[:app_names] = owned_apps + managed_apps + permitted_apps
      resources[:credential_set_ids] = owned_credentials + managed_credentials + permitted_credentials
    end
  end

  def self.group_by_user(permissions)
    permissions = permissions.group_by(&:user_id)

    output = permissions.map do |user_id, user_permits|
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

    if output.length == 1
      output.first
    else 
      output
    end
  end

  def self.group_by_resource(permissions)
    permissions = permissions.group_by { |permission| [permission.permissible_type, permission.permissible_id] }

    output = permissions.map do |(permissible_type, permissible_id), user_permits|
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

    if output.length == 1
      output.first
    else 
      output
    end
  end
end
