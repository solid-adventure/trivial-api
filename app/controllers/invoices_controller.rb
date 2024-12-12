class InvoicesController < ApplicationController
  before_action :set_organization, only: %i[index]
  before_action :set_invoice, only: %i[show]

  # GET /invoices
  def index
    @invoices = if @organization
                  Invoice.where(owner: @organization)
                else
                  current_user.associated_invoices
                end

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

    # organization/1/invoices
    def set_organization
      @organization = current_user.organizations.find(params[:organization_id]) if params[:organization_id]
    end
end

