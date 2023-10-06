class Organization < ApplicationRecord
  has_many :apps, as: :owner
  has_many :org_roles, dependent: :delete_all
  has_many :users, through: :org_roles

  validates :billing_email, presence: true
  validates :name, presence: true
end
