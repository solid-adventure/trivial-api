class InvoicesController < ApplicationController
  include Exportable
  self.export_serializer = InvoiceItemExportSerializer

  before_action :set_organization, only: %i[index]
  before_action :set_invoice, only: %i[show]
  before_action :set_and_authorize_invoices, only: %i[index]

  # GET /invoices
  def index
    if params[:format] == 'csv'
      handle_csv_export(InvoiceItem.with_invoice.where(invoice: @invoices))
    else
      render json: @invoices, status: :ok
    end
  end

  # GET /invoices/1
  def show
    authorize! :read, @invoice
    render json: @invoice
  end

  private
    # organization/1/invoices
    def set_organization
      @organization = current_user.organizations.find(params[:organization_id]) if params[:organization_id]
    end

    def set_invoice
      @invoice = Invoice.find(params[:id])
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

