class RegisterItemsController < ApplicationController
  include Exportable
  self.export_serializer = RegisterItemSerializer

  before_action :set_register
  before_action :set_register_item, only: %i[ show update ]
  before_action :set_register_items, only: %i[ index sum ]
  before_action :set_pagination, only: %i[index]
  before_action :set_ordering, only: %i[index]
  around_action :disable_audits, if: -> { current_user.role == 'client' }

  # GET /register_items
  def index
    order_register_items
    if params[:format] == 'csv'
      handle_csv_export(@register_items)
    else
      paginate_register_items
      response = {
        current_page: @page,
        total_pages: @total_pages,
        register_items: ActiveModel::Serializer::CollectionSerializer.new(@register_items, adapter: :attributes)
      }
      render json: response
    end
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
  end

  # GET /register_items/1
  def show
    authorize! :read, @register_item
    render json: @register_item, adapter: :attributes
  end

  # POST /register_items
  def create
    @register_item = RegisterItem.new
    @register_item.assign_attributes(register_item_params)
    @register_item.owner = @register.owner
    authorize! :create, @register_item
    if @register_item.save
      render json: @register_item, adapter: :attributes, status: :created
    else
      render json: @register_item.errors, status: :unprocessable_entity
    end
  end

  # POST /register_items/bulk_create
  def bulk_create
    max_items = 100
    raise "register_items must be an array" unless params[:register_items].is_a?(Array)
    raise "Maximum limit of #{max_items} items exceeded" if params[:register_items].size > max_items

    RegisterItem.transaction do
      register_ids = params[:register_items].map { |item| item[:register_id] }.uniq
      registers = Register.where(id: register_ids).index_by(&:id)
      register_items_attributes = params[:register_items].map do |item_params|
        @register = registers[item_params[:register_id]]
        register_item = RegisterItem.new
        register_item.assign_attributes(register_item_params(item_params))
        register_item.owner = @register&.owner
        authorize! :create, register_item
        register_item.attributes
      end
      # Let create! handle all validations, including missing references
      register_items = RegisterItem.create!(register_items_attributes)
      render json: register_items, adapter: :attributes, status: :created
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

  def sum
    col = params[:col] || 'amount'
    validated_column = RegisterItem.columns_hash[col]
    if validated_column && validated_column.type == :decimal
      render json: { sum: @register_items.sum(validated_column.name) }, status: :ok
    else
      render json: { error: "invalid sum column: #{col}" }, status: :bad_request
    end
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

  def filter_register_items
    search = params[:search] ? JSON.parse(params[:search]) : []
    if search.any?
      raise 'register_id required for search' unless @register
      @register_items = RegisterItem.search(@register_items, @register.meta, search)
    end
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

  def set_register_items
    @register_items = current_user.associated_register_items
    @register_items = @register_items.where(register_id: @register.id) if @register
    filter_register_items
  end

  def register_item_params(args=nil)
    register_item_params = args || params
    permitted_params = register_item_params.permit(:public_app_id, :unique_key, :description, :register_id, :amount, :units, :originated_at)
    if @register
      @register.meta.each do |column, label|
        next unless register_item_params[label]
        case register_item_params[label]
        when String, Integer, Float, BigDecimal
          permitted_params[column] = register_item_params[label]
        when ActionController::Parameters
          permitted_params[column] = register_item_params[label].to_json
        end
      end
    end
    permitted_params
  end
end
