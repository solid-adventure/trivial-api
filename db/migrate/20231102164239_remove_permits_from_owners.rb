class RemovePermitsFromOwners < ActiveRecord::Migration[7.0]
  def up
    User.all.each do |user|
      user.owned_apps.each do |app|
        app.revoke_all(user_ids: user.id)
      end
      user.owned_manifests.each do |manifest|
        manifest.revoke_all(user_ids: user.id)
      end
      user.owned_manifest_drafts.each do |manifest_draft|
        manifest_draft.revoke_all(user_ids: user.id)
      end
      user.owned_credential_sets.each do |credential_set|
        credential_set.revoke_all(user_ids: user.id)
      end
    end
  end

  def down
    User.all.each do |user|
      user.owned_apps.each do |app|
        app.grant_all(user_ids: user.id)
      end
      user.owned_manifests.each do |manifest|
        manifest.grant_all(user_ids: user.id)
      end
      user.owned_manifest_drafts.each do |manifest_draft|
        manifest_draft.grant_all(user_ids: user.id)
      end
      user.owned_credential_sets.each do |credential_set|
        credential_set.grant_all(user_ids: user.id)
      end
    end
  end
end
