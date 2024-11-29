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

  # POST /invoices
  def create
    @invoice = invoice.new(invoice_params)
    authorize! :create, @invoice

    if @invoice.save
      render json: @invoice, status: :created, location: @invoice
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /invoices/1
  def update
    authorize! :update, @invoice
    if @invoice.update(invoice_params)
      render json: @invoice
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  # DELETE /invoices/1
  def destroy
    authorize! :destroy, @invoice
    if @invoice.destroy
      render status: :ok
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    def invoice_params
      params.require(:invoice).permit(:payee_org_id, :payor_ord_id, :date, :notes, :currency, :total)
    end
end

