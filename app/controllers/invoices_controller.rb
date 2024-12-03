class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[show update destroy]

  # GET /invoices
  def index
    @invoices = current_user.associated_invoices
    render json: @invoices
  end

  # GET /invoices/1
  def show
    authorize! :read, @invoice
    render json: @invoice
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end
end

