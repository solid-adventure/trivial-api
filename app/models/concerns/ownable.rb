# app/models/concerns/ownable.rb

module Ownable
  extend ActiveSupport::Concern

  def transfer_ownership(new_owner:, revoke: false)
    if revoke
      previously_permitted_users = Permission.where(permissible: self).distinct.pluck(:user_id)

      self.revoke_all(user_ids: previously_permitted_users)
    end
    self.update(owner: new_owner)

    if new_owner.is_a?(Organization)
      members = new_owner.org_roles.where(role: 'member').pluck(:user_id)
      self.grant(user_ids: members, permit: :read)
    end
  end

  def admin?(user)
    if self.owner.is_a?(User)
      self.owner == user
    else # owner is Organization
      self.owner.org_roles.exists?(user: user, role: 'admin')
    end
  end

  def member?(user)
    if self.owner.is_a?(User)
      self.owner == user
    else # owner is Organization
      self.owner.org_roles.exists?(user: user, role: 'member')
    end
  end

end
