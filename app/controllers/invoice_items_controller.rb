class InvoiceItemsController < ApplicationController
  before_action :set_invoice
  before_action :set_invoice_item, only: %i[show]

  # GET /invoices/1/invoice_items
  def index
    authorize! :read, @invoice
    render json: @invoice.invoice_items
  end

  # GET /invoice/1/invoice_items/1
  def show
    authorize! :read, @invoice
    render json: @invoice_item
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:invoice_id])
    end

    def set_invoice_item
      @invoice_item = @invoice.invoice_items.find(params[:id])
    end
end
