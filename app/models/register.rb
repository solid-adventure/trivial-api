class Register < ApplicationRecord

  include Ownable
  include Permissible

  audited

  # Register identity basics
  validates :name, presence: true, uniqueness: { scope: :owner }
  validates :sample_type, acceptance: { accept: ['series', 'increment'] }
  validates :owner, presence: true

  # Expected values for items, denormalized to register_items
  validates :multiplier, presence: true
  validates :units, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  has_many :register_items, dependent: :destroy

  before_create :set_defaults

  def set_defaults
    self.sample_type ||= 'increment'
    self.multiplier ||= 1
    self.units ||= 'units'
  end

end
