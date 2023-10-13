class Permission < ApplicationRecord
  belongs_to :user
  belongs_to :permissible, polymorphic: true

  validates :user, presence: true
  validates :permissible, presence: true
  validates :permit, presence: true

  # Defined permissions and their bit alignment
  NO_PERMIT_BIT = 0b0
  READ_BIT = 0b1
  UPDATE_BIT = 0b10
  DELETE_BIT = 0b100
  TRANSFER_BIT = 0b1000
  GRANT_BIT = 0b10000
  REVOKE_BIT = 0b100000

  # Defined permissions hash
  PERMISSIONS_HASH = { 
    read: READ_BIT,
    update: UPDATE_BIT,
    destroy: DELETE_BIT,
    transfer: TRANSFER_BIT,
    grant: GRANT_BIT,
    revoke: REVOKE_BIT,
  }

  def self.grant(permissible:, user_id:, permit:)
    if permission = Permission.find_by(permissible: permissible, user_id: user_id, permit: NO_PERMIT_BIT)
      permission.update_column(:permit, PERMISSIONS_HASH[permit])
    else
      Permission.create(permissible: permissible, user_id: user_id, permit: PERMISSIONS_HASH[permit])
    end
  end

  def self.revoke(permissible:, user_id:, permit:)
    permissions = Permission.where(permissible: permissible, user_id: user_id)
    if permissions.count == 1
      permissions.first.update(permit: NO_PERMIT_BIT)
    else
      permissions.find_by(permit: PERMISSIONS_HASH[permit])&.delete
    end
  end

  def self.grant_all(permissible:, user_id:)
    if permission = Permission.find_by(permissible: permissible, user_id: user_id, permit: NO_PERMIT_BIT)
      permission.delete
    end
    PERMISSIONS_HASH.each do |_, bit|
      Permission.create(
        user_id: user_id,
        permissible: permissible,
        permit: bit,
      )
    end
  end

  def self.revoke_all(permissible:, user_id:)
    Permission.where(permissible: permissible, user_id: user_id).delete_all
    Permission.create(permissible: permissible, user_id: user_id, permit: NO_PERMIT_BIT)
  end
  
  def self.grant_org_permissible(permissible:, organization:)
    admin_user_ids = organization.org_roles.where(role: 'admin').pluck(:user_id)
    admin_user_ids.each do |user_id|
      Permission.grant_all(permissible: permissible, user_id: user_id)
    end
    
    member_user_ids = organization.org_roles.where(role: 'member').pluck(:user_id)
    member_user_ids.each do |user_id|
      Permission.grant(permissible: permissible, user_id: user_id, permit: :read)
    end
  end

  def self.revoke_org_permissible(permissible:, organization:)
    org_user_ids = organization.org_roles.pluck(:user_id)
    Permission.where(permissible: permissible, user_id: org_user_ids).delete_all

    org_user_ids.each do |user_id|
      Permission.create(permissible: permissible, user_id: user_id, permit: NO_PERMIT_BIT)
    end  
  end
end
