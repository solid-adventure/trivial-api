class PermissionsData < ActiveRecord::Migration[7.0]
  def up

    # Permit users full control of th their own apps
    User.all.each do |user|
      user.apps.each do |app|
        app.transfer_ownership(new_owner: user)
      end
      user.manifests.each do |manifest|
        manifest.transfer_ownership(new_owner: user)
      end
      user.manifest_drafts.each do |manifest_draft|
        manifest_draft.transfer_ownership(new_owner: user)
      end
      user.credential_sets.each do |credential_set|
        credential_set.transfer_ownership(new_owner: user)
      end
    end

    # Permit all users in Org to read the orgs apps to mimic pre-permissions behavior
    Organization.all.each do |org|
      org.users.each do |user|
        user.apps.each do |app|
          app.grant(permit: :read, user_ids: org.users.pluck(:id))
        end
        user.manifests.each do |manifest|
          manifest.grant(permit: :read, user_ids: org.users.pluck(:id))
        end
        user.manifest_drafts.each do |manifest_draft|
          manifest_draft.grant(permit: :read, user_ids: org.users.pluck(:id))
        end
        user.credential_sets.each do |credential_set|
          credential_set.grant(permit: :read, user_ids: org.users.pluck(:id))
        end
      end
    end

  end

  def down
    Permission.delete_all
  end

end



