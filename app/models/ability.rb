# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # all users can read public apps
    can :read, App, readable_by: 'public'
    can :read, Manifest, :app => { readable_by: 'public' }

    return unless user.present?

    can :manage, Organization do |organization|
      organization.roles.find(user.id)&.role == 'admin'
    end

    # Add more permissions as needed
    abilities = %i[read update destroy transfer grant revoke] 

    # Loop through permissions and resource types
    abilities.each do |ability|
      can ability, ActivityEntry do |resource|
        resource.permissions.find(user.id).permits?(ability)
      end

      can ability, App do |resource|
        resource.permissions.find(user.id).permits?(ability)
      end
      
      can ability, CredentialSet do |resource|
        resource.permissions.find(user.id).permits?(ability)
      end
      
      can ability, Manifest do |resource|
        resource.permissions.find(user.id).permits?(ability)
      end
      
      can ability, ManifestDraft do |resource|
        resource.permissions.find(user.id).permits?(ability)
      end
    end
  end
end
