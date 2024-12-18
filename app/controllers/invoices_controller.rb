class InvoicesController < ApplicationController
  include Exportable
  self.export_serializer = InvoiceItemExportSerializer

  before_action :set_organization, only: %i[index]
  before_action :set_invoice, only: %i[show destroy]
  before_action :set_and_authorize_invoices, only: %i[index]

  # GET /invoices
  def index
    if params[:format] == 'csv'
      handle_csv_export(collection: InvoiceItem.with_invoice.where(invoice: @invoices))
    else
      render json: @invoices, status: :ok
    end
  end

  # GET /invoices/1
  def show
    authorize! :read, @invoice
    render json: @invoice
  end

  # DELETE /invoices/1
  def destroy
    authorize! :destroy, @invoice
    render status: :ok if @invoice.destroy
  end

  # POST /invoices/create_from_register
  def create_from_register
    register = Register.find(params[:register_id])
    payee = register.owner
    authorize! :read, register
    creator = Services::InvoiceCreator.new(
      register,
      payee,
      @payor,
      params[:timezone],
      params[:start_at],
      params[:end_at],
      params[:group_by],
      params[:group_by_period],
      params[:search],
      params[:strategy]
    )
    invoice_ids = creator.create!
    render json: {invoice_ids: }
  rescue ArgumentError => e
    render json: {error: e.message}, status: :bad_request
  end

  private
    # organization/1/invoices
    def set_organization
      @organization = current_user.organizations.find(params[:organization_id]) if params[:organization_id]
    end

    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    def set_payor
      @payor = Organization.find_by_customer_id(params[:payor_customer_id]) if params[:payor_customer_id]
    end

    def set_and_authorize_invoices
      @invoices = current_user.associated_invoices
      @invoices = @invoices.where(owner: @organization) if @organization
      filter_invoices
    end

    def filter_invoices
      search = params[:search] ? JSON.parse(params[:search]) : []
      if search.any?
        @invoices = Invoice.search(@invoices, search)
      end
    end
end

