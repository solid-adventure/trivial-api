class CredentialSet < ApplicationRecord
  belongs_to :user, inverse_of: :credential_sets

  validates :name, :credential_type, presence: true

  def credentials
    @credentials ||= CredentialSetCredentials.find_or_build_by_user_and_name user, credentials_name
  end

  private

  def credentials_name
    "credentialSet/#{id}"
  end

end
