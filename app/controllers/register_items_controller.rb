class RegisterItemsController < ApplicationController
  before_action :set_register_item, only: %i[ show update ]
  before_action :set_register
  before_action :set_pagination, only: %i[index]
  before_action :set_ordering, only: %i[index]

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

      order_register_items
      paginate_register_items
      response = {
        current_page: @page,
        total_pages: @total_pages,
        register_items: ActiveModel::Serializer::CollectionSerializer.new(@register_items, adapter: :attributes)
      }

      render json: response
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

  def order_register_items
    if @register
      order = RegisterItem.resolved_ordering(@order_by, @ordering_direction, @register.meta)
    else
      order = RegisterItem.create_ordering(@order_by, @ordering_direction)
    end
    @register_items = @register_items.order(Arel.sql(order))
  end

  def paginate_register_items
    raise 'invalid per_page param' unless @per_page.positive?
    raise 'invalid page param' unless @page.positive?

    @total_pages = (@register_items.count.to_f / @per_page).ceil
    offset = (@page - 1) * @per_page
    @register_items = @register_items.limit(@per_page).offset(offset)
  end

  def set_pagination
    @per_page = params[:per_page] ? params[:per_page].to_i : MAX_PER_PAGE
    @per_page = [@per_page, MAX_PER_PAGE].min
    @page = params[:page] ? params[:page].to_i : 1
  end

  def set_ordering
    @order_by = params[:order_by] || "originated_at"
    @ordering_direction = params[:ordering_direction] || "DESC"
  end

  def set_register
    if @register_item
      @register = @register_item.register
    else
      @register = Register.find_by_id(params[:register_id])
    end
  end

  def set_register_item
    @register_item = RegisterItem.find(params[:id])
  end

  def register_item_params
    permitted_params = params.permit(:unique_key, :description, :register_id, :amount, :units, :originated_at)
    if @register
      @register.meta.each do |column, label|
        permitted_params[column] = params[label] if params[label]
      end
    end
    permitted_params
  end

end
