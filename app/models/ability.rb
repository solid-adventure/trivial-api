# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)


    return unless user.present?

    # Until we have UI in place to support admin filtering by customer, this would be too much
    # Admins can manage everything
    # if user.admin?
    #   can :manage, :all
    # end

    # Users with no customers can manage their own resources
    can :manage, ActivityEntry, user: user
    can :manage, App, user: user
    can :manage, CredentialSet, user: user
    can :manage, Manifest, user: user
    can :manage, ManifestDraft, user: user

    # Users with customers can manage their own, plus their teammates
    return unless user.customers.length > 0
    can :manage, App, user_id: user.customers.map{ |c| c.users.map{ |u| u.id }}.flatten


    # Define abilities for the user here. For example:
    #
    #   return unless user.present?
    #   can :read, :all
    #   return unless user.admin?
    #   can :manage, :all
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, published: true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md
  end
end
