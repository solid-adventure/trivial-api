class CredentialSet < ApplicationRecord
  belongs_to :user, inverse_of: :credential_sets

  validates :name, :credential_type, presence: true
end
