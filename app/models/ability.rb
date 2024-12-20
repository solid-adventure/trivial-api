# frozen_string_literal: true

class Ability
  include CanCan::Ability
  include PermissionConstants

  def initialize(user)

    # all users can read public apps
    can :read, App, readable_by: 'public'
    can :read, Manifest, :app => { readable_by: 'public' }

    return unless user.present?

    if user.client?
      can :manage, :all
    end

    can :read, Organization do |organization|
      organization.org_roles.find_by(user: user)
    end

    can :manage, Organization do |organization|
      organization.org_roles.find_by(user: user)&.role == 'admin'
    end

    can :revoke, OrgRole do |org_role|
      org_role.user_id == user.id
    end

    can [:grant, :revoke], Organization do |organization|
      organization.org_roles.find_by(user: user)&.role == 'admin'
    end

    # ActivityEntry blocks Permission Blocks
    can [:manage, :grant, :revoke, :transfer], ActivityEntry do |entry|
      entry.app.admin?(user)
    end
    can [:read], ActivityEntry do |entry|
      entry.app.member?(user)
    end
    can :read, ActivityEntry do |entry|
      Permission.find_by(permissible: entry.app, user: user, permit: READ_BIT)
    end
    can :update, ActivityEntry do |entry|
      Permission.find_by(permissible: entry.app, user: user, permit: UPDATE_BIT)
    end
    can :destroy, ActivityEntry do |entry|
      Permission.find_by(permissible: entry.app, user: user, permit: DELETE_BIT)
    end

    # App Permission Blocks
    can [:manage, :grant, :revoke, :transfer], App do |app|
      app.admin?(user)
    end
    can [:read], App do |app|
      app.member?(user)
    end
    can :read, App do |app|
      Permission.find_by(permissible: app, user: user, permit: READ_BIT)
    end
    can :update, App do |app|
      Permission.find_by(permissible: app, user: user, permit: UPDATE_BIT)
    end
    can :destroy, App do |app|
      Permission.find_by(permissible: app, user: user, permit: DELETE_BIT)
    end
    can :grant, App do |app|
      Permission.find_by(permissible: app, user: user, permit: GRANT_BIT)
    end
    can :revoke, App do |app|
      Permission.find_by(permissible: app, user: user, permit: REVOKE_BIT)
    end

    # CredentialSet Permission Blocks
    can [:manage, :grant, :revoke, :transfer], CredentialSet do |credential|
      credential.admin?(user)
    end
    # What you do not see is CredentialSet :read via org membership. This is deliberate.
    can :read, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: READ_BIT)
    end
    can :update, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: UPDATE_BIT)
    end
    can :destroy, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: DELETE_BIT)
    end
    can :grant, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: GRANT_BIT)
    end
    can :revoke, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: REVOKE_BIT)
    end

    # Manifest Permission Blocks
    can [:manage, :grant, :revoke, :transfer], Manifest do |manifest|
      manifest.admin?(user)
    end
    can [:read], Manifest do |manifest|
      manifest.member?(user)
    end
    can :read, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: READ_BIT)
    end
    can :update, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: UPDATE_BIT)
    end
    can :destroy, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: DELETE_BIT)
    end
    can :grant, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: GRANT_BIT)
    end
    can :revoke, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: REVOKE_BIT)
    end

    # ManifestDraft Permission Blocks
    can [:manage, :grant, :revoke, :transfer], ManifestDraft do |draft|
      draft.admin?(user)
    end
    can [:read], ManifestDraft do |draft|
      draft.member?(user)
    end
    can :read, ManifestDraft do |draft|
      Permission.find_by(permissible: draft, user: user, permit: READ_BIT)
    end
    can :update, ManifestDraft do |draft|
      Permission.find_by(permissible: draft, user: user, permit: UPDATE_BIT)
    end
    can :destroy, ManifestDraft do |draft|
      Permission.find_by(permissible: draft, user: user, permit: DELETE_BIT)
    end
    can :grant, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: GRANT_BIT)
    end
    can :revoke, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: REVOKE_BIT)
    end

    # Register Permission Blocks
    can [:manage, :grant, :revoke, :transfer], Register do |register|
      register.admin?(user)
    end
    can [:read], Register do |register|
      register.member?(user)
    end
    can :read, Register do |register|
      Permission.find_by(permissible: register, user: user, permit: READ_BIT)
    end
    can :update, Register do |register|
      Permission.find_by(permissible: register, user: user, permit: UPDATE_BIT)
    end
    can :destroy, Register do |register|
      Permission.find_by(permissible: register, user: user, permit: DELETE_BIT)
    end
    can :grant, Register do |register|
      Permission.find_by(permissible: register, user: user, permit: GRANT_BIT)
    end
    can :revoke, Register do |register|
      Permission.find_by(permissible: register, user: user, permit: REVOKE_BIT)
    end

    # RegisterItem Permission Blocks
    can [:manage, :grant, :revoke, :transfer], RegisterItem do |item|
      item.admin?(user)
    end
    can [:read], RegisterItem do |item|
      item.member?(user)
    end
    can :read, RegisterItem do |item|
      Permission.find_by(permissible: item, user: user, permit: READ_BIT)
    end
    can :update, RegisterItem do |item|
      Permission.find_by(permissible: item, user: user, permit: UPDATE_BIT)
    end
    can :destroy, RegisterItem do |item|
      Permission.find_by(permissible: item, user: user, permit: DELETE_BIT)
    end
    can :grant, RegisterItem do |item|
      Permission.find_by(permissible: item, user: user, permit: GRANT_BIT)
    end
    can :revoke, RegisterItem do |item|
      Permission.find_by(permissible: item, user: user, permit: REVOKE_BIT)
    end

    # Dashboard Permission Blocks
    can [:read], Dashboard do |dashboard|
      dashboard.member?(user)
    end
    can :read, Dashboard do |dashboard|
      Permission.find_by(permissible: dashboard, user: user, permit: READ_BIT)
    end
    can :update, Dashboard do |dashboard|
      Permission.find_by(permissible: dashboard, user: user, permit: UPDATE_BIT)
    end
    can :destroy, Dashboard do |dashboard|
      Permission.find_by(permissible: dashboard, user: user, permit: DELETE_BIT)
    end
    can :grant, Dashboard do |dashboard|
      Permission.find_by(permissible: dashboard, user: user, permit: GRANT_BIT)
    end
    can :revoke, Dashboard do |dashboard|
      Permission.find_by(permissible: dashboard, user: user, permit: REVOKE_BIT)
    end
    can [:manage, :grant, :revoke, :transfer], Dashboard do |dashboard|
      dashboard.admin?(user)
    end

    # Chart Permission Blocks
    can [:read], Chart do |chart|
      chart.dashboard.admin?(user)
    end
    can :read, Chart do |chart|
      Permission.find_by(permissible: chart.dashboard, user: user, permit: READ_BIT)
    end
    can :update, Chart do |chart|
      Permission.find_by(permissible: chart.dashboard, user: user, permit: UPDATE_BIT)
    end
    can :destroy, Chart do |chart|
      Permission.find_by(permissible: chart.dashboard, user: user, permit: DELETE_BIT)
    end
    can [:manage, :grant, :revoke, :transfer], Chart do |chart|
      chart.dashboard.admin?(user)
    end

    # Invoice Permission Blocks
    can [:read], Invoice do |invoice|
      invoice.member?(user)
    end
    can :read, Invoice do |invoice|
      Permission.find_by(permissible: invoice, user: user, permit: READ_BIT)
    end
    can [:manage, :grant, :revoke, :transfer], Invoice do |invoice|
      invoice.admin?(user)
    end
  end
end
