class Organization < ApplicationRecord
  has_many :apps, as: :owner
  has_many :org_roles
  has_many :users, through: :org_roles

  before_create :set_token

  validates :billing_email, presence: true
  validates :name, presence: true

  def set_token
    self.token = create_token if self.token.blank?
  end

  def username
    name.gsub(' ', '_').gsub('.', '').downcase
  end

  def create_token
    proposed = SecureRandom.hex(10)
    Customer.where(token: proposed).size > 0 ? define_token : proposed
  end
end
