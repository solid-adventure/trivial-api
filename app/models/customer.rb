class Customer < ApplicationRecord

	before_create :set_token

	validates :billing_email, presence: true
	validates :name, presence: true

	def set_token
		self.token = create_token if self.token.blank?
	end

	def create_token
		proposed = SecureRandom.hex(10)
    Customer.where(token: proposed).size > 0 ? define_token : proposed
  end

end
