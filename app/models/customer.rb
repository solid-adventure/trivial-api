class Customer < ApplicationRecord

	has_and_belongs_to_many :users
	has_many :apps, through: :users
	has_many :orders, primary_key: :token, foreign_key: :customer_token
	has_many :shipments, primary_key: :token, foreign_key: :customer_token

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
