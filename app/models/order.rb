class Order < ApplicationRecord

	belongs_to :customer, primary_key: :token, foreign_key: :customer_token
	has_many :shipments

	validates :platform_name, presence: true
	validates :customer_token, presence: true

end
