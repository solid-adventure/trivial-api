class InvoiceItemController < ApplicationController
  before_action :set_invoice
  before_action :set_invoice_item, only: %i[show update destroy]

  # GET /invoices/1/invoice_items
  def index
    authorize! :read, @invoice
    render json: @invoice.invoice_items
  end

  # GET /invoice/1/invoice_items/1
  def show
    authorize! :read, @invoice_item
    render json: @invoice_item
  end

  # POST invoices/1/invoice_items
  def create
    @invoice_item = InvoiceItem.new(invoice_item_params)
    @invoice_item.invoice = @invoice
    authorize! :create, @invoice_item

    if @invoice_item.save
      render json: @invoice_item, status: :created
    else
      render json: @invoice_item.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT invoices/1/invoice_items/1
  def update
    authorize! :update, @invoice_item
    if invoice_item_params[:invoice_id]
      new_invoice = Invoice.find(invoice_item_params[:invoice_id])
      authorize! :update new_invoice
    end

    if @invoice_item.update(invoice_item_params)
      render json: @invoice_item
    else
      render json: @invoice_item.errors, status: :unprocessable_entity
    end
  end

  # DELETE invoices/1/invoice_items/1
  def destroy
    authorize! :destroy, @invoice_item
    if @invoice_item.destroy
      render status: :ok
    else
      render json: @invoice_item.errors, status: :unprocessable_entity
    end
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:invoice_id])
    end

    def set_invoice_item
      @invoice_item = @invoice.invoice_items.find(params[:id])
    end

    def invoice_item_params
      params.require(:invoice_item).permit(:invoice_id, :income_account, :income_account_group, :quantity, :unit_price, :extended_amount)
    end
end
