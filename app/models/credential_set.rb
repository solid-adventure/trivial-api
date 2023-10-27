class CredentialSet < ApplicationRecord
  include Ownable
  include Permissible

  # old user association to be deprecated for ownership and permissions
  belongs_to :user, inverse_of: :credential_sets
  
  # new owner based association
  belongs_to :owner, polymorphic: true
  
  # new permission based multi-user association
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  validates :name, :credential_type, presence: true

  before_create :set_external_id

  def credentials
    @credentials ||= CredentialSetCredentials.find_or_build_by_user_and_name user, credentials_name
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

  private

  def credentials_name
    "credentialSet/#{external_id}"
  end

  def set_external_id
    self.external_id = SecureRandom.uuid
  end

end
