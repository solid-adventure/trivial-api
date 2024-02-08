class RegisterItemsController < ApplicationController
  before_action :set_register
  before_action :set_register_item, only: %i[ show ]
  before_action :set_meta_columns, only: %i[ create ]

  # GET /register_items
  def index
    @register_items = current_user.associated_register_items
    render json: @register_items, adapter: :attributes
  end

  # GET /register_items/1
  def show
    authorize! :read, @register_item
    render json: @register_item, adapter: :attributes
  end

  # POST /register_items
  def create
    @register_item = RegisterItem.new(register_item_params)
    @register_item.owner = @register.owner

    authorize! :create, @register_item
    if @register_item.save
      render json: @register_item, adapter: :attributes, status: :created
    else
      render json: @register_item.errors, status: :unprocessable_entity
    end
  end

  private
  def set_register
    @register = Register.find(params[:register_id])
  end

  def set_register_item
    @register_item = RegisterItem.find(param[:id])
  end

  def register_item_params
    register_meta = @register.meta.symbolize_keys
    params.require(:register_item).permit(*register_meta.values, :unique_key, :description, :register_id, :amount, :units)
  end
end
