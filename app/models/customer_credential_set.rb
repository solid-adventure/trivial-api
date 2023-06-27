class CustomerCredentialSet
  attr_accessor :name, :credential_type, :external_id, :created_at, :updated_at

  def initialize(customer, name, credential_type, external_id, path, created_at, updated_at)
    @customer = customer
    @name = name
    @credential_type = credential_type
    @external_id = external_id
    @path = path
    @created_at = created_at
    @updated_at = updated_at
  end


  def credentials
    @credentials ||= Credentials.find_or_build_by_customer_and_name(@customer, credentials_name, @path)
  end

  def update!(arg)
    raise ActionController::BadRequest.new('Customer credentials cannot be updated')
  end

  def destroy!
    raise ActionController::BadRequest.new('Customer credentials cannot be deleted')
  end

  def api_attrs
    {
      'id' => @external_id,
      'name' => @name,
      'credential_type' => @credential_type,
      'created_at' => @created_at,
      'updated_at' => @updated_at
    }
  end

  private

	def credentials_name
    "credentials/#{@customer.token}"
  end
end
