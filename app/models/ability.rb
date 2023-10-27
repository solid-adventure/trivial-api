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

    
    can :manage, ActivityEntry, owner: user
    can :manage, App, owner: user
    can :manage, CredentialSet, owner: user
    can :manage, Manifest, owner: user
    can :manage, ManifestDraft, owner: user

    can :read, ActivityEntry do |entry|
      Permission.find_by(permissible: entry.app, user: user, permit: READ_BIT)
    end
    can :read, App do |app|
      Permission.find_by(permissible: app, user: user, permit: READ_BIT)
    end
    can :read, CredentialSet do |credential|
      Permission.find_by(permissible: credential, user: user, permit: READ_BIT)
    end
    can :read, Manifest do |manifest|
      Permission.find_by(permissible: manifest, user: user, permit: READ_BIT)
    end
    can :read, ManifestDraft do |draft|
      Permission.find_by(permissible: draft, user: user, permit: READ_BIT)
    end
  end
end
