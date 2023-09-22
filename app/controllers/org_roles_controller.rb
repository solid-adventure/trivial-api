class OrgRolesController < ApplicationController
  before_action :set_org_role, only: %i[ show update destroy ]

  # GET /org_roles
  def index
    @org_roles = current_user.org_roles

    render json: @org_roles
  end

  # GET /org_roles/1
  def show
    render json: @org_role
  end

  # POST /org_roles
  def create
    @org_role = OrgRole.new(org_role_params)

    if @org_role.save
      render json: @org_role, status: :created, location: @org_role
    else
      render json: @org_role.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /org_roles/1
  def update
    if @org_role.update(org_role_params)
      render json: @org_role
    else
      render json: @org_role.errors, status: :unprocessable_entity
    end
  end

  # DELETE /org_roles/1
  def destroy
    @org_role.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_org_role
      @org_role = OrgRole.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def org_role_params
      params.require(:org_role).permit(:role, :user_id, :organization_id)
    end
end
