class CredentialSet < ApplicationRecord
  validate :validate_owner_type, on: :update
  belongs_to :owner, polymorphic: true
  # belongs_to :user, inverse_of: :credential_sets
  # belongs_to  :customer, inverse_of: :credential_sets

  validates :name, :credential_type, presence: true
  before_create :set_external_id

  def credentials
    @credentials ||= Credentials.find_or_build_by_owner_and_name owner, credentials_name
  end

  def api_attrs
    {
      'id' => external_id,
      'name' => name,
      'credential_type' => credential_type,
      'created_at' => created_at,
      'updated_at' => updated_at
    }
  end

  # For now the only customer credential is the Trivial Datastore credential that should never
  # be removed from the account once created. We block any destroy request sent for customer
  # credentials to ensure a user cannot accidentally do something destructive. This can be
  # enhanced in the future if customer credentials need to be actively managed.
  def destroy!
    if owner_type == 'Customer'
      raise ActionController::BadRequest.new('Customer credential sets cannot be deleted')
    end
    super
  end

  private

  def credentials_name
    "credentialSet/#{external_id}"
  end

  def set_external_id
    self.external_id = SecureRandom.uuid
  end

  def validate_owner_type
    if owner_type == 'Customer'
      errors.add(:base, "Cannot update credential sets for customers.")
    end
  end
end
