module Overrides
  class InvitationsController < Devise::InvitationsController
    include InvitableMethods
    before_action :authenticate_user!, :validate_metadata!, only: :create 
    before_action :resource_from_invitation_token, only: [:edit, :update]

    def create
      invited_user = invite_resource
      
      resource_invited = invited_user.errors.empty?

      yield invited_user if block_given?

      if resource_invited
        render json: { success: ['Invite Created.'] }, status: :created
      else 
        render json: { errors: ['Invite Failed']}, status: :unprocessable_entity
      end
    end

    def update
      user = accept_resource
      invitation_accepted = user.errors.empty?

      yield resource if block_given?

      if invitation_accepted
        user.accept_role!

        render json: { success: ['Invite Accepted'] }, status: :accepted
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    protected

    def validate_metadata!
      metadata = invite_params[:invitation_metadata]

      unless OrgRole::ROLES.include?(metadata[:role])
        render json: { errors: ['Invalid Role for Invite']}, status: :unprocessable_entity
        return
      end

      unless Organization.find_by(id: metadata[:org_id])
        render json: { errors: ['Invalid Organization for Invite']}, status: :unprocessable_entity
        return
      end
    end

    def invite_resource(&block)
      User.invite!(invite_params, current_inviter, &block)
    end

    def accept_resource
      User.accept_invitation!(accept_invite_params)
    end

    def invite_params
      params.require(:invitation).permit(:name, :email, :invitation_token, :provider, :skip_invitation, invitation_metadata: [:org_id, :role])
    end

    def accept_invite_params
      params.require(:invitation).permit(:password, :password_confirmation, :invitation_token)
    end
  end
end
