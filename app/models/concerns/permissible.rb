module Permissible
  extend ActiveSupport::Concern
  include PermissionConstants

  # takes a user or array of users and grants them a specific permission for the given permissible
  def grant(user_ids:, permit:)
    user_ids = Array(user_ids)
    permissions = Permission.where(permissible: self, user_id: user_ids)

    permissions.where(permit: NO_PERMIT_BIT).update_all(permit: PERMISSIONS_HASH[permit])
    permits_exist = permissions.where(permit: PERMISSIONS_HASH[permit]).pluck(:user_id)

    user_ids = user_ids - permits_exist
    permits_to_create = []
    user_ids.each do |user_id| 
      permits_to_create << { 
        permissible: self,
        user_id: user_id,
        permit: PERMISSIONS_HASH[permit]
      }
    end
    Permission.create(permits_to_create)
  end

  # takes a user or array of users and revokes a specific permission for the given permissible
  def revoke(user_ids:, permit:)
    user_ids = Array(user_ids)
    permissions = Permission.where(permissible: self, user_id: user_ids, permit: PERMISSIONS_HASH[permit])
    user_ids = permissions.pluck(:user_id)

    permits_to_delete = Permission.none
    user_ids.each do |user_id|
      if Permission.where(permissible: self, user_id: user_id).count > 1
        permits_to_delete = permits_to_delete.or(permissions.where(user_id: user_id))
      end
    end
    permissions.where.not(user_id: permits_to_delete.pluck(:user_id)).update_all(permit: NO_PERMIT_BIT)
    permits_to_delete.delete_all
  end

  # takes a user or array of users and grants them all possible permissions for a given permissible
  def grant_all(user_ids:)
    user_ids = Array(user_ids)
    existing_permits = Permission.where(permissible: self, user_id: user_ids)
    existing_permits.where(permit: NO_PERMIT_BIT).delete_all

    permits_to_create = []
    user_ids.each do |user_id|
      missing_permits = PERMISSIONS_HASH.values - existing_permits.where(user_id: user_id).pluck(:permit)
      missing_permits.each do |permit|
        permits_to_create << { 
          permissible: self,
          user_id: user_id,
          permit: permit
        }
      end
    end
    Permission.create(permits_to_create)
  end

  # takes a user or array of users and revokes all of their permissions for a given permissible
  def revoke_all(user_ids:)
    user_ids = Array(user_ids)
    permissions = Permission.where(permissible: self, user_id: user_ids)
    return unless permissions.count > 0

    user_ids = permissions.distinct.pluck(:user_id)
    permissions.delete_all

    permits_to_create = []
    user_ids.each do |user_id|
      permits_to_create << { 
        permissible: self, 
        user_id: user_id, 
        permit: NO_PERMIT_BIT 
      }
    end
    Permission.create(permits_to_create)
  end
end
