class PermissionsController < ApplicationController
  before_action :set_resource, except: %i[ index_user ]
  before_action :set_user, except: %i[ index_resource transfer ]
  before_action :set_new_owner, only: %i[ transfer ]

  # GET /permissions/users/:user_id
  def index_user
    permissions = Permission.permissions_for(@user)
    render json: permissions, status: :ok
  end

  # GET /permissions/:permissible_type/:permissible_id
  def index_resource
    authorize! :grant, @permissible
    permissions = Permission.where(permissible: @permissible)
    permissions = Permission.group_by_resource(permissions)
    render json: permissions, status: :ok
  end

  # POST /permission/:permit/:permissible_type/:permissible_id/users/:user_id
  def grant
    authorize! :grant, @permissible
    if @permissible.grant(user_ids: @user.id, permit: params[:permit].to_sym)
      permissions = Permission.where(permissible: @permissible, user: @user)
      permissions = Permission.group_by_user(permissions)
      render json: permissions, status: :ok
    else
      render json: { message: 'Grant Failed' }, status: :unprocessable_entity
    end
  end

  # POST /permissions/:permissible_type/:permissible_id/users/:user_id
  def grant_all
    authorize! :grant, @permissible
    if @permissible.grant_all(user_ids: @user.id)
      permissions = Permission.where(permissible: @permissible, user: @user)
      permissions = Permission.group_by_user(permissions)
      render json: permissions, status: :ok
    else
      render json: { message: 'Grant Failed' }, status: :unprocessable_entity
    end
  end

  # DELETE /permission/:permit/:permissible_type/:permissible_id/users/:user_id
  def revoke
    authorize! :revoke, @permissible
    if @permissible.revoke(user_ids: @user.id, permit: params[:permit].to_sym)
      render json: { message: 'Revoke OK' }, status: :no_content
    else 
      render json: { message: 'Revoke Failed' }, status: :unprocessable_entity
    end
  end

  # DELETE /permissions/:permissible_type/:permissible_id/users/:user_id
  def revoke_all
    authorize! :revoke, @permissible
    if @permissible.revoke_all(user_ids: @user.id)
      render json: { message: 'Revoke All OK' }, status: :no_content
    else 
      render json: { message: 'Revoke All Failed' }, status: :unprocessable_entity
    end
  end

  # PUT permissions/:permissible_type/:permissible_id/:owner_type/:owner_id
  def transfer
    authorize! :transfer, @permissible
    render json: { message: 'Transfer to Owner Unauthorized' }, status: :unauthorized unless authorize_transfer!

    if @permissible.transfer_ownership(new_owner: @new_owner)
      render json: { message: 'Tranfer Ownership OK'}, status: :ok
    else
      render json: { message: 'Tranfer Ownership Failed' }, status: :unprocessable_entity
    end
  end

  private
    def authorize_transfer!
      return true if @new_owner == current_user # This line is necessary for allowing a user to transfer from an Organization to themselves
      @new_owner.is_a?(Organization) && current_user.organizations.exists?(@new_owner)
    end

    # Use callback to set the resource to determine permission actions
    def set_resource
      begin
        permissible_class = params[:permissible_type].classify.constantize
        permissible_id = params[:permissible_id]
        @permissible = permissible_class.find(permissible_id)
      rescue NameError => e
        render json: { message: "#{params[:permissible_type]} Class Type Not Found" }, status: :unprocessable_entity
      end
    end

    # Use callback to set the user to determine permission actions
    def set_user
      @user = User.find(params[:user_id])
    end

    def set_new_owner
      begin
        owner_class = params[:new_owner_type].classify.constantize
        owner_id = params[:new_owner_id]
        @new_owner = owner_class.find(owner_id)
      rescue NameError => e
        render json: { message: "#{params[:permissible_type]} Class Type Not Found" }, status: :unprocessable_entity
      end
    end

    # Only allow a list of trusted parameters through
    def permission_params
      params.require(:permission).permit(:permissible_type, :permissible_id, :user_id, :permit)
    end
end
