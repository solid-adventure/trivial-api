class Shipment < ApplicationRecord

	belongs_to :customer, primary_key: :token, foreign_key: :customer_token
	belongs_to :order

	validates :customer_token, presence: true

	before_validation :set_customer_token

	def set_customer_token
		self.customer_token = self.order.customer_token
	end

end
