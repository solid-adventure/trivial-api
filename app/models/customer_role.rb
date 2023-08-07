class CustomerRole < ApplicationRecord
  belongs_to :customer
  has_many :users
  has_many :permissions
end
