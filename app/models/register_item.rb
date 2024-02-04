class RegisterItem < ApplicationRecord

  include Ownable
  include Permissible

  belongs_to :register

  # Item identiy basics
  validates :description, presence: true
  validates :amount, presence: true
  validates :uniqueness_key, uniqueness: { case_sensitive: true, scope: :register_id }
  validates :register, presence: true
  validates :multiplier, presence: true
  validates :units, presence: true

  # Denormalized from register
  validates :multiplier, presence: true
  validates :units, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  # Common scopes for reports
  scope :between, ->(start_at, end_at) { where("created_at >= ? AND created_at <= ?", start_at, end_at) }

  # Denormalized from register
  # attr_accessor :multiplier, :units

  after_initialize :set_register_attrs

  def set_register_attrs
    self.multiplier = register.multiplier
    self.units = register.units
  end

  def amount
    super * multiplier
  end

# TODO We want the setter to convert from 1.56 to 156 for storage, but something is wrong with this implementation

# Creating:
# 3.1.2 :008 > register_item = register.register_items.new(amount: 1.00, description: "First transaction")
# /Library/WebServer/solid-adventure/trivial-api/app/models/register_item.rb:36:in `*': nil can't be coerced into Float (TypeError)

# Updating:
# 3.1.2 :002 ri.amount = 3.00
# 3.1.2 :003 => 3.0
# 3.1.2 :004 > ri.save
# 3.1.2 :005 > ri.amount.to_s
#  => "0.0" <<<<< NOPE

  # def amount=(val)
  #   super(val * multiplier)
  # end

end
