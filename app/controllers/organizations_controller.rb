class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[ show update destroy create_org_role update_org_role delete_org_role ]

  # GET /organizations
  def index
    if @organizations = current_user.organizations
      render json: @organizations, adapter: :attributes
    else
      render json: { message: 'User has no Organizations' }, status: :no_content
    end
  end

  # GET /organizations/1
  def show
    authorize! :show, @organization
    if @organization.present?
      render json: @organization, include_users: true, adapter: :attributes
    else
      render json: { message: 'No Organization Found' }, status: :no_content
    end 
  end

  # POST /organizations
  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      @org_role = OrgRole.create(user: current_user, organization: @organization, role: 'admin')
      render json: @organization, adapter: :attributes, status: :created
    else
      render json: @organization.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /organizations/1
  def update
    authorize! :update, @organization
    if @organization&.update(organization_params)
      render json: @organization, adapter: :attributes
    else
      render json: @organization.errors, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/1
  def destroy
    authorize! :destroy, @organization
    @organization.destroy
    render json: { message: 'Delete OK' }, status: :no_content
  end

  # POST /organizations/1/create_org_role
  def create_org_role
    authorize! :grant, @organization
    user = User.find(params[:user_id])
    role = params[:role]

    @org_role = OrgRole.new(organization: @organization, user: user, role: role)
    if @org_role.save
      render json: @organization, include_users: true, adapter: :attributes, status: :created
    else
      render json: { errors: @org_role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /organizations/1/update_org_role
  def update_org_role
    authorize! :grant, @organization
    user = User.find(params[:user_id])
    role = params[:role]

    @org_role = OrgRole.find_by(organization: @organization, user: user)
    if @org_role.update(role: role)
      render json: @organization, include_users: true, adapter: :attributes
    else
      render json: { errors: @org_role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/1/delete_org_role
  def delete_org_role
    user = User.find(params[:user_id])

    if @org_role = OrgRole.find_by(organization: @organization, user: user)
      if can?(:revoke, @organization) || can?(:revoke, @org_role)
        @org_role.destroy
        render json: { message: 'Delete OK' }, status: :no_content
      else
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    else
      render json: { errors: @org_role.errors.full_messages }, status: :unprocessable_entity
    end 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_organization
      @organization = Organization.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def organization_params
      params.require(:organization).permit(:name, :billing_email)
    end
end
