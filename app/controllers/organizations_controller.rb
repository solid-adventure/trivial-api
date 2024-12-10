class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[ show update destroy delete_org_role invoices]

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

  # DELETE /organizations/1/delete_org_role
  def delete_org_role
    user = User.find(params[:user_id])
    @org_role = OrgRole.find_by!(organization: @organization, user: user)

    if can?(:revoke, @organization) || can?(:revoke, @org_role)
      @org_role.destroy
      render json: { message: 'Delete OK' }, status: :no_content
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  # GET /organizations/1/invoices
  def invoices
    @invoices = Invoice.where(owner: @organization)
    # authorize! :read, @invoices
    render json: ActiveModel::Serializer::CollectionSerializer.new(@invoices, adapter: :attributes)
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
