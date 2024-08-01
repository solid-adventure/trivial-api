class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[ show update destroy ]

  # GET /organizations
  def index
    @organizations = current_user.associated_organizations
    render json: @organizations, adapter: :attributes
  end

  # GET /organizations/1
  def show
    authorize! :show, @organization
    render json: @organization, include_users: true, adapter: :attributes
  end

  # POST /organizations
  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      @org_role = OrgRole.create!(user: current_user, organization: @organization, role: 'admin')
      render json: @organization, adapter: :attributes, status: :created
    else
      render json: @organization.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /organizations/1
  def update
    authorize! :update, @organization
    if @organization.update(organization_params)
      render json: @organization, adapter: :attributes
    else
      render json: @organization.errors, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/1
  def destroy
    authorize! :destroy, @organization
    if @organization.destroy
      render status: :no_content
    else
      render json: @organization.errors, status: :unprocessable_entity
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
