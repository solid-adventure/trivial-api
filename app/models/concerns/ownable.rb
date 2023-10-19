# app/models/concerns/ownable.rb

module Ownable
  extend ActiveSupport::Concern

  def transfer_ownership(new_owner:, revoke: false)
    if revoke
      previously_permitted_users = Permission.where(permissible: self).distinct.pluck(:user_id)

      Permission.revoke_all(permissible: self, user_ids: previously_permitted_users)
    end
    self.update(owner: new_owner)

    if new_owner.is_a?(User)
      Permission.grant_all(permissible: self, user_ids: new_owner.id)
    else # new_owner is Organization
      admins = new_owner.org_roles.where(role: 'admin').pluck(:user_id)
      members = new_owner.org_roles.where(role: 'member').pluck(:user_id)

      Permission.grant_all(permissible: self, user_ids: admins)
      Permission.grant(permissible: self, user_ids: members, permit: :read)
    end
  end
end
