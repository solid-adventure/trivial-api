class RegisterItemsController < ApplicationController
  before_action :set_register
  before_action :set_register_item, only: %i[ show update ]
  before_action :set_pagination_params, only %i[index]
  before_action :set_ordering_params, only %i[index]

  # GET /register_items
  def index
    begin
      @register_items = current_user.associated_register_items
      @register_items = @register_items.where(register_id: @register.id) if @register
      
      search = params[:search] ? JSON.parse(params[:search]) : []
      if search.any?
        raise 'register_id required for search' unless @register
        @register_items = RegisterItem.search(@register_items, @register.meta, search)
      end

      if @register
        order = RegisterItem.resolved_ordering(params[:order_by], params[:ordering_direction], @register.meta)
      else
        order = RegisterItem.create_ordering(params[:order_by], params[:ordering_direction])
      end
      @register_items = @register_items.order(order)
      
      response_data = paginate_register_items

      render json: response_data
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
    if @register_item.update(register_item_params)
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
  MAX_PER_PAGE = 100

  def paginate_register_items
    offset = (params[:page] - 1) * @per_page
    @register_items = @register_items.limit(@per_page).offset(offset)

    total_pages = (@register_items.count.to_f / @per_page).ceil
    return {
      current_page: params[:page],
      total_pages: total_pages,
      register_items: ActiveModel::Serializer::CollectionSerializer.new(@register_items, adapter: :attributes)
    }
  end

  def set_pagination_params
    params[:per_page] ||= MAX_PER_PAGE
    params[:page] = params[:page] ? params[:page] : 1
    
    if !params[:per_page].is_a?(Integer) || params[:per_page] < 1 
      render_errors('per_page param invalid', status: :unprocessable_entity)
    else if !params[:page].is_a?(Integer) || params[:page] < 1
      render_errors('page param invalid', status: :unprocessable_entity)
    else
      @per_page = params[:per_page]
    end
  end

  def set_ordering_params
    params[:order_by] ||= "originated_at"
    params[:ordering_direction] ||= "DESC"
  end

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
