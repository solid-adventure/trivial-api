class PermissionsController < ApplicationController
  before_action :set_permission, only: %i[ show update destroy ]

  # GET /permissions
  def index
    @permissions = current_user.permissions

    render json: @permissions
  end

  # POST /permissions
  def create
    @permission = Permission.new(permission_params)

    if @permission.save
      render json: @permission, status: :created, location: @permission
    else
      render json: @permission.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /permissions/1
  def update
    if @permission.update(permission_params)
      render json: @permission
    else
      render json: @permission.errors, status: :unprocessable_entity
    end
  end

  # DELETE /permissions/1
  def destroy
    @permission.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_permission
      @permission = Permission.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def permission_params
      params.fetch(:permission, {})
    end
end
