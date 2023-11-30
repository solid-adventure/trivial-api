module Overrides
  class InvitationsController < Devise::InvitationsController
    include InvitableMethods
    before_action :authenticate_user!, only: :create
    before_action :resource_from_invitation_token, only: [:edit, :update]

    def create
      params[:invitation][:skip_invitation] = true

      invited_user = invite_resource
      invited_user.update_column(:invitation_metadata, metadata_params.to_s)
      
      # this line is necessary to retrieve the token when debugging given the lack of mailer
      # puts "invitation_token is #{invited_user.raw_invitation_token}"
      
      # FIXME: needs custom mailer view. fails internally due to lack of root_url
      # invited_user.deliver_invitation
      
      resource_invited = invited_user.errors.empty?

      yield invited_user if block_given?

      if resource_invited
        render json: { success: ['User created.'] }, status: :created
      else 
        render json: { errors: ['User invite failed']}, status: :unprocessable_entity
      end
    end

    # route does not exist
    def edit
      # FIXME: use correct redirect
      # redirect_to user_setup_url
    end

    def update
      user = accept_resource
      invitation_accepted = user.errors.empty?

      yield resource if block_given?

      if invitation_accepted
        user.accept_role!

        sign_in :user, user
        render json: { success: ['User updated.'] }, status: :accepted
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    protected

    def invite_resource(&block)
      User.invite!(invite_params, current_inviter, &block)
    end

    def accept_resource
      User.accept_invitation!(accept_invite_params)
    end

    def metadata_params
      params.require(:invitation_metadata).permit(:org_id, :role)
    end

    def invite_params
      params.require(:invitation).permit(:name, :email, :invitation_token, :provider, :skip_invitation)
    end

    def accept_invite_params
      params.require(:invitation).permit(:password, :password_confirmation, :invitation_token)
    end
  end
end
