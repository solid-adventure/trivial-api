# app/models/concerns/ownable.rb

module Ownable
  extend ActiveSupport::Concern

  def transfer_ownership(new_owner:, revoke: false)
    if revoke
      if self.owner.is_a?(User)
        Permission.revoke_all(permissible: self, user_id: self.owner.id)
      else # old owner is an Organization
        Permission.revoke_org_permissible(permissible: self, organization: self.owner)
      end
    end
    self.update(owner: new_owner)

    if new_owner.is_a?(User)
      Permission.grant_all(permissible: self, user_id: new_owner.id)
    else # new_owner is Organization
      Permission.grant_org_permissible(permissible: self, org: new_owner.id)
    end
  end
end

