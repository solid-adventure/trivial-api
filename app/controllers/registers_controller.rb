class RegistersController < ApplicationController
  before_action :set_register, only: %i[ show ]

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
    @register.owner = current_user

    authorize! :create, @register
    if @register.save
      render json: @register, adapter: :attributes
    else
      render json: @register.errors, status: :unprocessable_entity
    end
  end

  private
  def set_register
    @register = Register.find(param[:id])
  end

  def register_params
    params.require(:register).permit(:name, :sample_type, :units, meta: {})
  end
end
