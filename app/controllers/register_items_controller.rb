class RegisterItemsController < ApplicationController
  before_action :set_register
  before_action :set_register_item, only: %i[ show update ]

  # GET /register_items
  def index
    begin
      @register_items = current_user.associated_register_items
      search = params[:search] ? JSON.parse(params[:search]) : []
      if search.any?
        raise 'register_id required for search' unless @register
        @register_items = @register_items.where(register_id: @register.id)
        @register_items = RegisterItem.search(@register_items, @register.meta, search)
      end
      render json: @register_items, adapter: :attributes
    rescue StandardError => exception
      render_errors(exception, status: :unprocessable_entity)
    end
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

  # PUT /register_items/1
  def update
    authorize! :update, @register_item
    if @register_item.update(updateable_params)
      render json: @register_item, adapter: :attributes
    else
      render json: @register_item.errors, status: :unprocessable_entity
    end
  end

  def columns
    authorize! :index, RegisterItem
    raise 'register_id required for columns query' unless @register
    
    searchable_columns = RegisterItem.get_columns(RegisterItem::SEARCHABLE_COLUMNS) + @register.meta.values
    render json: searchable_columns.to_json, status: :ok
  end

  private
  def set_register
    @register = Register.find_by_id(params[:register_id])
  end

  def set_register_item
    @register_item = RegisterItem.find(params[:id])
  end

  def register_item_params
    if @register && @register.meta.present?
      params.permit(:unique_key, :description, :register_id, :amount, :units, :originated_at, @register.meta.values)
    else
      params.permit(:unique_key, :description, :register_id, :amount, :units, :originated_at)
    end
  end

end
