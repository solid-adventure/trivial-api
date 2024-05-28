require 'search'

class RegisterItem < ApplicationRecord

  include Ownable
  include Permissible
  include Search

  audited

  # includes only non-meta searchable columns
  # meta columns are handled by self.search
  SEARCHABLE_COLUMNS = %w[originated_at description amount units unique_key].freeze

  belongs_to :register

  @@initialized_registers = {}
  @@initialization_lock = Mutex.new

  # Item identiy basics
  validates :description, presence: true
  validates :amount, presence: true
  validates :unique_key, uniqueness: { case_sensitive: true, scope: :register_id }
  validates :units, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  # Common scopes for reports
  scope :between, ->(start_at, end_at) { where("originated_at >= ? AND originated_at <= ?", start_at, end_at) }

  # Denormalized from register
  before_create :set_register_attrs
  after_initialize :initialize_by_register

  def set_register_attrs
    self.units ||= register.units
  end

  def self.new(args)
    super(args)
  rescue ActiveRecord::UnknownAttributeError
    register = Register.find(args[:register_id])
    @@initialization_lock.synchronize do
      register_meta_attributes(register.meta)
      @@initialized_registers[register.id] = true
    end
    super(args)
  end

  def resolved_column(label, column_labels)
    RegisterItem.resolved_column(label, column_labels)
  end

  def self.resolved_column(label, column_labels)
    return label if label.in? column_names
    meta_column = column_labels.invert[label]
    raise "No meta column found for #{label}" unless meta_column
    return meta_column
  end

  def self.sanitize(str)
    str.gsub(' ', '_').underscore.gsub(/[^a-zA-Z0-9_]/, '')
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

  private

  def initialize_by_register
    raise "You must provide a register_id to create register items" unless register_id

    @@initialization_lock.synchronize do
      unless @@initialized_registers[register_id]
        RegisterItem.register_meta_attributes(register.meta)
        @@initialized_registers[register_id] = true
      end
    end
  end

  def self.register_meta_attributes(column_labels)
    return unless column_labels
    column_labels.keys.each do |attr_name|

      label = sanitize(column_labels[attr_name])
      define_method label do
        self[resolved_column(label, column_labels)]
      end

      define_method "#{label}=" do |val|
        self[resolved_column(label, column_labels)] = val
      end
    end
  end

end
