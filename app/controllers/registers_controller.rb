class RegistersController < ApplicationController
  before_action :set_register, only: %i[ show update ]

  # GET /registers
  def index
    @registers = current_user.associated_registers
    render json: @registers, adapter: :attributes
  end

  # GET /registers/1
  def show
    authorize! :read, @register
    render json: @register, adapter: :attributes
  end

  # POST /registers
  def create
    @register = Register.new(register_params)
    @register.owner = current_user unless @register.owner # support for client_keys, which pass the owner in the request

    authorize! :create, @register
    if @register.save
      render json: @register, adapter: :attributes
    else
      render json: @register.errors, status: :unprocessable_entity
    end
  end

  # PUT /registers/1
  def update
    authorize! :update, @register
    if @register.update!(register_params)
      render json: @register, adapter: :attributes
    else
      render json: @register.errors, status: :unprocessable_entity
    end
  end

  private
  def set_register
    @register = Register.find(params[:id])
  end

  def register_params
    params.permit(:name, :sample_type, :units, :owner_type, :owner_id, meta: {})
  end
end
