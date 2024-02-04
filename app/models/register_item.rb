class RegisterItem < ApplicationRecord

  include Ownable
  include Permissible

  belongs_to :register

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
  scope :between, ->(start_at, end_at) { where("created_at >= ? AND created_at <= ?", start_at, end_at) }

  # Denormalized from register
  before_create :set_register_attrs
  after_initialize :register_meta_attributes

  def set_register_attrs
    self.units ||= register.units
  end

  def self.new(args)
    super(args)
  rescue ActiveRecord::UnknownAttributeError
    raise "You must provide a register_id to create register items" unless args[:register_id]
    register = Register.find(args[:register_id])
    raise "No register found for ID #{args[:register_id]}" unless register
    register_meta_attributes(register.meta)
    super(args)
  end

  def register_meta_attributes
    raise "You must provide a register_id to create register items" unless register_id
    RegisterItem.register_meta_attributes(register.meta)
  end

  def self.register_meta_attributes(column_labels)
    column_labels.keys.each do |attr_name|

      label = sanitize(column_labels[attr_name])
      define_method label do
        self[meta_column(label, column_labels)]
      end

      define_method "#{label}=" do |val|
        self[meta_column(label, column_labels)] = val
      end
    end
  end

  def meta_column(label, column_labels)
    RegisterItem.meta_column(label, column_labels)
  end

  def self.meta_column(label, column_labels)
    return label if label.in? %w( register_id owner_id owner_type created_at updated_at)
    out = column_labels.find{ |k,v|  v==label }.first
    raise "No meta column found for #{label}" unless out
    return out
  end

  def self.sanitize(str)
    str.gsub(' ', '_').underscore.gsub(/[^a-zA-Z0-9_]/, '')
  end

end
