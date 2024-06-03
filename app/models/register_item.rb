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
  validates :register, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  # Common scopes for reports
  scope :between, ->(start_at, end_at) { where("originated_at >= ? AND originated_at <= ?", start_at, end_at) }

  # Denormalized from register
  before_create :set_register_attrs

  def set_register_attrs
    self.units ||= register.units
  end

  def resolved_column(label)
    RegisterItem.resolved_column(label, register.meta)
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

end
