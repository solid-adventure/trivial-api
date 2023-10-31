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
  end
end
