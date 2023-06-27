class Customer < ApplicationRecord

	has_and_belongs_to_many :users
	has_many :apps, through: :users
	has_many :orders, primary_key: :token, foreign_key: :customer_token
	has_many :shipments, primary_key: :token, foreign_key: :customer_token

	before_create :set_token

	validates :billing_email, presence: true
	validates :name, presence: true

	def credentials
    @credentials ||= Credentials.find_or_build_by_customer_and_name self, credentials_name, nil
  end

	def credential_sets
		@credential_sets ||= build_customer_credential_sets
	end

	def credential_set_by_external_id(external_id)
		credential_sets.find { |credential_set| credential_set.external_id == external_id }
	end

	def set_token
		self.token = create_token if self.token.blank?
	end

	def username
		name.gsub(' ', '_').gsub('.', '').downcase
	end

	def credentials_external_id(path)
		"customer_#{token}_#{path}"
	end

	def credentials_name
    "credentials/#{token}"
  end

	def create_token
		proposed = SecureRandom.hex(10)
    Customer.where(token: proposed).size > 0 ? define_token : proposed
  end

	def customer_credential_sets(customer)
    @credential_sets ||= build_customer_credential_sets(customer)
  end

	def build_customer_credential_sets
    @credential_sets = []
		secret_value = self.credentials.secret_value
    secret_value.keys.each do |path|
      credential = secret_value[path]
      if credential.has_key?('name') and credential.has_key?('credential_type')
				external_id = self.credentials_external_id(path)
        credential_set = CustomerCredentialSet.new(self, credential['name'], credential['credential_type'],
        	external_id, path, self.created_at, self.updated_at)
        @credential_sets.append(credential_set)
      end
    end
    @credential_sets
  end

end
