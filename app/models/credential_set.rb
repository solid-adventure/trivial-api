class CredentialSet < ApplicationRecord
  belongs_to :user, inverse_of: :credential_sets
end
