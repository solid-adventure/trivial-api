require 'search'
require 'csv'

class RegisterItem < ApplicationRecord

  include Ownable
  include Permissible
  include Search

  audited associated_with: :register, owned_audits: true

  # includes only non-meta searchable columns
  # meta columns are handled by self.search
  SEARCHABLE_COLUMNS = %w[originated_at description amount units unique_key invoice_id].freeze

  belongs_to :register
  belongs_to :app, optional: true
  belongs_to :invoice, optional: true
  has_many :activity_entries

  default_scope do
    includes(:register)
  end

  @@initialized_registers = {}
  @@initialization_lock = Mutex.new

  # Item identiy basics
  validates :description, presence: true
  validates :amount, presence: true
  validates :unique_key, uniqueness: { case_sensitive: true, scope: :register_id }
  validates :units, presence: true
  validates :register, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  # Common scopes for reports
  scope :between, ->(start_at, end_at) { where("originated_at >= ? AND originated_at <= ?", start_at, end_at) }

  # Denormalized from register
  before_create :set_register_attrs

  # Allow the public app id to derive the internal app id
  attr_reader :public_app_id

  def reference_name
    register.reference_name
  end

  def set_register_attrs
    self.units ||= register.units
  end

  def public_app_id=(value)
    @public_app_id = value
    self.app = App.find_by_name!(value) if value.present?
  end

  def resolved_column(label)
    RegisterItem.resolved_column(label, register.meta)
  end

  def to_csv_row(meta_symbols=[], meta_db_column_names=[])
    header = self.class.csv_header(meta_symbols)
    values = [
      "id",
      "register_id",
      "owner_type",
      "owner_id",
      "unique_key",
      "description",
      "amount",
      "units",
      "originated_at",
      "created_at"
    ]
    .concat(meta_db_column_names)
    values = values.map { |value| self[value] }
    CSV::Row.new(header, values, false) #false - means its not a header
  end

  def self.csv_header(meta_symbols=[])
    symbols = [
        :id,
        :register_id,
        :owner_type,
        :owner_id,
        :unique_key,
        :description,
        :amount,
        :units,
        :originated_at,
        :created_at
      ]
    symbols += meta_symbols
    names = symbols.map { |s| s.to_s }
    CSV::Row.new(symbols, names, true)  #true - means its a header
  end

  def self.resolved_column(label, column_labels)
    return label if label.in? column_names
    meta_column = column_labels.invert[label]
    raise "No meta column found for #{label}" unless meta_column
    return meta_column
  end

  def self.search(items, column_labels, search)
    search.each do |hash|
      col = resolved_column(hash['c'], column_labels)
      next unless SEARCHABLE_COLUMNS.include?(col) || col.match(/\Ameta\d\z/)
      query = create_query(col, hash['o'], hash['p'])
      items = items.where(query)
    end
    return items
  end

  def self.resolved_ordering(order_by, ordering_direction, column_labels)
    column = resolved_column(order_by, column_labels)
    return create_ordering(column, ordering_direction)
  end

  # this method assumes that register_items is a relation which will pick up any newly created void transactions
  def self.void!(register_items)
    transaction do
      # this is for fast look up by unique key without hitting the database
      unique_keys = register_items.pluck(:unique_key).to_set

      void_transactions = []
      register_items.each do |item|
        next if item.unique_key.end_with?(' - VOID')

        void_key = item.unique_key + ' - VOID'
        unless unique_keys.include?(void_key)
          void_attributes = item.attributes
            .except('id', 'invoice_id', 'created_at', 'updated_at', 'amount', 'unique_key', 'description')
          void_transactions << void_attributes.merge(
            created_at: Time.current,
            updated_at: Time.current,
            unique_key: item.unique_key + ' - VOID',
            description: item.description + ' - VOID',
            amount: -1 * item.amount
          )
        end
      end
      insert_all!(void_transactions) unless void_transactions.empty?

      # ensure that all items sum to 0
      unless register_items.sum(:amount) == 0.0
        raise "[VOID ERROR] sum of items is not zero"
      end
    end
  end
end
