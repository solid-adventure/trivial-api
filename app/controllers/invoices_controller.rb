class InvoicesController < ApplicationController
  before_action :set_organization, only: %i[index]
  before_action :set_invoice, only: %i[show]

  # GET /invoices
  def index
    @invoices = current_user.associated_invoices
    @invoices = @invoices.where(owner: @organization) if @organization

    render json: @invoices
  end

  # GET /invoices/1
  def show
    authorize! :read, @invoice
    render json: @invoice
  end

  # POST /invoices/create_from_register
  def create_from_register
    register = Register.find(params[:register_id])
    payee = register.owner
    payor = Organization.first # TODO Implement
    authorize! :read, register
    creator = Services::InvoiceCreator.new(
      register,
      payee,
      payor,
      params[:timezone],
      params[:start_at],
      params[:end_at],
      params[:group_by],
      params[:group_by_period],
      params[:search]
    )
    invoice_ids = creator.create!
    render json: {invoice_ids: }
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    # organization/1/invoices
    def set_organization
      @organization = current_user.organizations.find(params[:organization_id]) if params[:organization_id]
    end
end

