class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[ show update destroy create_org_role update_org_role delete_org_role ]

  # GET /organizations
  def index
    @organizations = current_user.organizations

    render json: @organizations, adapter: :attributes
  end

  # GET /organizations/1
  def show
    render json: @organization, include_users: true, adapter: :attributes
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
    if @organization.update(organization_params)
      render json: @organization, adapter: :attributes
    else
      render json: @organization.errors, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/1
  def destroy
    @organization.destroy
  end

  # POST /organizations/1/create_org_role
  def create_org_role
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

    @org_role = OrgRole.find_by(organization: @organization, user: user)
    @org_role.destroy
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
